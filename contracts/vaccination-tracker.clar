;; Animal Vaccination Tracker Contract
;; Tracks animal vaccinations with health compliance verification and digital certificate issuance

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PET (err u102))
(define-constant ERR_NOT_VETERINARIAN (err u103))
(define-constant ERR_EXPIRED_LICENSE (err u104))
(define-constant ERR_DUPLICATE_RECORD (err u105))
(define-constant ERR_INVALID_VACCINE (err u106))

;; Data Variables
(define-data-var pet-counter uint u0)
(define-data-var vaccination-counter uint u0)
(define-data-var certificate-counter uint u0)
(define-data-var vet-counter uint u0)

;; Data Maps
(define-map pets 
  uint 
  {
    name: (string-ascii 50),
    species: (string-ascii 30),
    breed: (string-ascii 50),
    owner: principal,
    birth-date: uint,
    microchip-id: (string-ascii 20),
    registered-at: uint,
    status: (string-ascii 20)
  }
)

(define-map veterinarians 
  principal 
  {
    name: (string-ascii 100),
    license-number: (string-ascii 30),
    practice-name: (string-ascii 100),
    authorized: bool,
    license-expiry: uint,
    vaccination-count: uint
  }
)

(define-map vaccinations 
  uint 
  {
    pet-id: uint,
    vaccine-name: (string-ascii 50),
    vaccine-type: (string-ascii 30),
    administered-by: principal,
    administration-date: uint,
    expiry-date: uint,
    lot-number: (string-ascii 30),
    status: (string-ascii 20)
  }
)

(define-map health-certificates 
  uint 
  {
    pet-id: uint,
    vaccination-id: uint,
    issue-date: uint,
    expiry-date: uint,
    purpose: (string-ascii 50),
    veterinarian: principal,
    status: (string-ascii 20)
  }
)

(define-map pet-vaccination-history 
  uint 
  {
    pet-id: uint,
    vaccination-ids: (list 50 uint),
    last-vaccination: uint,
    compliance-status: (string-ascii 20)
  }
)

;; Private Functions
(define-private (is-authorized-vet (vet principal))
  (match (map-get? veterinarians vet)
    vet-data 
    (and 
      (get authorized vet-data)
      (> (get license-expiry vet-data) burn-block-height)
    )
    false
  )
)

(define-private (validate-pet-id (pet-id uint))
  (is-some (map-get? pets pet-id))
)

;; Public Functions

;; Register Veterinarian
(define-public (register-veterinarian 
  (vet principal)
  (name (string-ascii 100))
  (license-number (string-ascii 30))
  (practice-name (string-ascii 100))
  (license-duration uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set veterinarians vet {
      name: name,
      license-number: license-number,
      practice-name: practice-name,
      authorized: true,
      license-expiry: (+ burn-block-height license-duration),
      vaccination-count: u0
    })
    
    (var-set vet-counter (+ (var-get vet-counter) u1))
    (ok (var-get vet-counter))
  )
)

;; Register Pet
(define-public (register-pet 
  (name (string-ascii 50))
  (species (string-ascii 30))
  (breed (string-ascii 50))
  (owner principal)
  (birth-date uint)
  (microchip-id (string-ascii 20)))
  (let (
    (pet-id (+ (var-get pet-counter) u1))
  )
    (asserts! (is-authorized-vet tx-sender) ERR_NOT_VETERINARIAN)
    
    (map-set pets pet-id {
      name: name,
      species: species,
      breed: breed,
      owner: owner,
      birth-date: birth-date,
      microchip-id: microchip-id,
      registered-at: burn-block-height,
      status: "active"
    })
    
    (var-set pet-counter pet-id)
    (ok pet-id)
  )
)

;; Record Vaccination
(define-public (record-vaccination 
  (pet-id uint)
  (vaccine-name (string-ascii 50))
  (vaccine-type (string-ascii 30))
  (expiry-duration uint)
  (lot-number (string-ascii 30)))
  (let (
    (vaccination-id (+ (var-get vaccination-counter) u1))
  )
    (asserts! (is-authorized-vet tx-sender) ERR_NOT_VETERINARIAN)
    (asserts! (validate-pet-id pet-id) ERR_INVALID_PET)
    
    (map-set vaccinations vaccination-id {
      pet-id: pet-id,
      vaccine-name: vaccine-name,
      vaccine-type: vaccine-type,
      administered-by: tx-sender,
      administration-date: burn-block-height,
      expiry-date: (+ burn-block-height expiry-duration),
      lot-number: lot-number,
      status: "valid"
    })
    
    ;; Update vet count
    (match (map-get? veterinarians tx-sender)
      vet-data
      (map-set veterinarians tx-sender 
        (merge vet-data { vaccination-count: (+ (get vaccination-count vet-data) u1) })
      )
      false
    )
    
    (var-set vaccination-counter vaccination-id)
    (ok vaccination-id)
  )
)

;; Issue Health Certificate
(define-public (issue-certificate 
  (pet-id uint)
  (vaccination-id uint)
  (validity-duration uint)
  (purpose (string-ascii 50)))
  (let (
    (cert-id (+ (var-get certificate-counter) u1))
  )
    (asserts! (is-authorized-vet tx-sender) ERR_NOT_VETERINARIAN)
    (asserts! (validate-pet-id pet-id) ERR_INVALID_PET)
    
    (map-set health-certificates cert-id {
      pet-id: pet-id,
      vaccination-id: vaccination-id,
      issue-date: burn-block-height,
      expiry-date: (+ burn-block-height validity-duration),
      purpose: purpose,
      veterinarian: tx-sender,
      status: "valid"
    })
    
    (var-set certificate-counter cert-id)
    (ok cert-id)
  )
)

;; Update Pet Status
(define-public (update-pet-status (pet-id uint) (new-status (string-ascii 20)))
  (match (map-get? pets pet-id)
    pet-data
    (begin
      (asserts! (or (is-eq tx-sender (get owner pet-data)) (is-authorized-vet tx-sender)) ERR_UNAUTHORIZED)
      
      (map-set pets pet-id 
        (merge pet-data { status: new-status })
      )
      
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; Read-only Functions

(define-read-only (get-pet-info (pet-id uint))
  (map-get? pets pet-id)
)

(define-read-only (get-veterinarian-info (vet principal))
  (map-get? veterinarians vet)
)

(define-read-only (get-vaccination-record (vaccination-id uint))
  (map-get? vaccinations vaccination-id)
)

(define-read-only (get-certificate-info (certificate-id uint))
  (map-get? health-certificates certificate-id)
)

(define-read-only (verify-vaccination (vaccination-id uint))
  (match (map-get? vaccinations vaccination-id)
    vacc-data 
    (and 
      (is-eq (get status vacc-data) "valid")
      (> (get expiry-date vacc-data) burn-block-height)
    )
    false
  )
)

(define-read-only (is-certificate-valid (certificate-id uint))
  (match (map-get? health-certificates certificate-id)
    cert-data 
    (and 
      (is-eq (get status cert-data) "valid")
      (> (get expiry-date cert-data) burn-block-height)
    )
    false
  )
)

(define-read-only (get-pet-count)
  (var-get pet-counter)
)

(define-read-only (get-vaccination-count)
  (var-get vaccination-counter)
)

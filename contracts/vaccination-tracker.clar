;; Vaccination Tracker Smart Contract
;; Tracks animal vaccinations with health compliance verification and digital certificate issuance

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-not-found (err u103))
(define-constant err-invalid-vaccine (err u104))
(define-constant err-expired-certificate (err u105))
(define-constant err-invalid-date (err u106))
(define-constant err-pet-not-found (err u107))
(define-constant err-vet-not-authorized (err u108))

;; Data Variables
(define-data-var vaccination-counter uint u0)
(define-data-var certificate-counter uint u0)
(define-data-var pet-counter uint u0)

;; Data Maps

;; Authorized veterinarians
(define-map authorized-veterinarians
  principal
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    authorized-at: uint,
    is-active: bool
  }
)

;; Pet registry
(define-map pets
  uint ;; pet-id
  {
    owner: principal,
    pet-name: (string-ascii 50),
    species: (string-ascii 30),
    breed: (string-ascii 50),
    date-of-birth: uint,
    microchip-id: (optional (string-ascii 30)),
    registered-at: uint
  }
)

;; Vaccination records
(define-map vaccination-records
  uint ;; vaccination-id
  {
    pet-id: uint,
    vaccine-type: (string-ascii 50),
    vaccine-name: (string-ascii 100),
    batch-number: (string-ascii 50),
    administered-by: principal,
    administration-date: uint,
    expiration-date: uint,
    next-due-date: uint,
    certificate-issued: bool,
    notes: (optional (string-ascii 200))
  }
)

;; Digital certificates
(define-map vaccination-certificates
  uint ;; certificate-id
  {
    vaccination-id: uint,
    pet-id: uint,
    issued-at: uint,
    valid-until: uint,
    issued-by: principal,
    certificate-hash: (buff 32),
    is-valid: bool
  }
)

;; Pet vaccination history tracking
(define-map pet-vaccination-history
  uint ;; pet-id
  (list 100 uint) ;; list of vaccination-ids
)

;; Compliance requirements by vaccine type
(define-map vaccine-compliance-periods
  (string-ascii 50) ;; vaccine-type
  uint ;; validity period in blocks (~144 blocks per day)
)

;; Private Functions

(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-authorized-veterinarian (vet principal))
  (match (map-get? authorized-veterinarians vet)
    veterinarian (get is-active veterinarian)
    false
  )
)

(define-private (add-vaccination-to-history (pet-id uint) (vaccination-id uint))
  (let
    (
      (current-history (default-to (list) (map-get? pet-vaccination-history pet-id)))
    )
    (map-set pet-vaccination-history pet-id (unwrap-panic (as-max-len? (append current-history vaccination-id) u100)))
  )
)

;; Public Functions

;; Register a new pet
(define-public (register-pet 
  (pet-name (string-ascii 50))
  (species (string-ascii 30))
  (breed (string-ascii 50))
  (date-of-birth uint)
  (microchip-id (optional (string-ascii 30))))
  (let
    (
      (new-pet-id (+ (var-get pet-counter) u1))
    )
    (map-set pets new-pet-id {
      owner: tx-sender,
      pet-name: pet-name,
      species: species,
      breed: breed,
      date-of-birth: date-of-birth,
      microchip-id: microchip-id,
      registered-at: stacks-block-height
    })
    (var-set pet-counter new-pet-id)
    (ok new-pet-id)
  )
)

;; Add authorized veterinarian (contract owner only)
(define-public (add-authorized-veterinarian
  (vet-address principal)
  (vet-name (string-ascii 100))
  (license-number (string-ascii 50)))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (asserts! (is-none (map-get? authorized-veterinarians vet-address)) err-already-registered)
    (map-set authorized-veterinarians vet-address {
      name: vet-name,
      license-number: license-number,
      authorized-at: stacks-block-height,
      is-active: true
    })
    (ok true)
  )
)

;; Deactivate veterinarian (contract owner only)
(define-public (deactivate-veterinarian (vet-address principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (match (map-get? authorized-veterinarians vet-address)
      veterinarian
        (begin
          (map-set authorized-veterinarians vet-address (merge veterinarian {is-active: false}))
          (ok true)
        )
      err-not-found
    )
  )
)

;; Record a new vaccination
(define-public (record-vaccination
  (pet-id uint)
  (vaccine-type (string-ascii 50))
  (vaccine-name (string-ascii 100))
  (batch-number (string-ascii 50))
  (administration-date uint)
  (expiration-date uint)
  (next-due-date uint)
  (notes (optional (string-ascii 200))))
  (let
    (
      (new-vaccination-id (+ (var-get vaccination-counter) u1))
      (pet-info (unwrap! (map-get? pets pet-id) err-pet-not-found))
    )
    (asserts! (is-authorized-veterinarian tx-sender) err-vet-not-authorized)
    (asserts! (< administration-date expiration-date) err-invalid-date)
    (map-set vaccination-records new-vaccination-id {
      pet-id: pet-id,
      vaccine-type: vaccine-type,
      vaccine-name: vaccine-name,
      batch-number: batch-number,
      administered-by: tx-sender,
      administration-date: administration-date,
      expiration-date: expiration-date,
      next-due-date: next-due-date,
      certificate-issued: false,
      notes: notes
    })
    (var-set vaccination-counter new-vaccination-id)
    (add-vaccination-to-history pet-id new-vaccination-id)
    (ok new-vaccination-id)
  )
)

;; Issue digital certificate for a vaccination
(define-public (issue-certificate (vaccination-id uint) (certificate-hash (buff 32)))
  (let
    (
      (new-certificate-id (+ (var-get certificate-counter) u1))
      (vaccination (unwrap! (map-get? vaccination-records vaccination-id) err-not-found))
    )
    (asserts! (is-authorized-veterinarian tx-sender) err-vet-not-authorized)
    (asserts! (is-eq (get administered-by vaccination) tx-sender) err-not-authorized)
    (map-set vaccination-certificates new-certificate-id {
      vaccination-id: vaccination-id,
      pet-id: (get pet-id vaccination),
      issued-at: stacks-block-height,
      valid-until: (get expiration-date vaccination),
      issued-by: tx-sender,
      certificate-hash: certificate-hash,
      is-valid: true
    })
    (map-set vaccination-records vaccination-id (merge vaccination {certificate-issued: true}))
    (var-set certificate-counter new-certificate-id)
    (ok new-certificate-id)
  )
)

;; Revoke certificate (for corrections or fraud prevention)
(define-public (revoke-certificate (certificate-id uint))
  (let
    (
      (certificate (unwrap! (map-get? vaccination-certificates certificate-id) err-not-found))
    )
    (asserts! (or (is-contract-owner) (is-eq (get issued-by certificate) tx-sender)) err-not-authorized)
    (map-set vaccination-certificates certificate-id (merge certificate {is-valid: false}))
    (ok true)
  )
)

;; Set vaccine compliance period (contract owner only)
(define-public (set-vaccine-compliance-period (vaccine-type (string-ascii 50)) (validity-period uint))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (map-set vaccine-compliance-periods vaccine-type validity-period)
    (ok true)
  )
)

;; Read-only Functions

;; Get pet information
(define-read-only (get-pet-info (pet-id uint))
  (ok (unwrap! (map-get? pets pet-id) err-pet-not-found))
)

;; Get vaccination record
(define-read-only (get-vaccination-record (vaccination-id uint))
  (ok (unwrap! (map-get? vaccination-records vaccination-id) err-not-found))
)

;; Get certificate information
(define-read-only (get-certificate (certificate-id uint))
  (ok (unwrap! (map-get? vaccination-certificates certificate-id) err-not-found))
)

;; Get pet vaccination history
(define-read-only (get-pet-vaccination-history (pet-id uint))
  (ok (default-to (list) (map-get? pet-vaccination-history pet-id)))
)

;; Check if veterinarian is authorized
(define-read-only (is-vet-authorized (vet-address principal))
  (ok (is-authorized-veterinarian vet-address))
)

;; Get veterinarian info
(define-read-only (get-veterinarian-info (vet-address principal))
  (ok (unwrap! (map-get? authorized-veterinarians vet-address) err-not-found))
)

;; Verify certificate validity
(define-read-only (verify-certificate (certificate-id uint))
  (let
    (
      (certificate (unwrap! (map-get? vaccination-certificates certificate-id) err-not-found))
    )
    (ok {
      is-valid: (and (get is-valid certificate) (<= stacks-block-height (get valid-until certificate))),
      expiration-block: (get valid-until certificate),
      issued-by: (get issued-by certificate)
    })
  )
)

;; Check compliance status for a pet
(define-read-only (check-compliance-status (pet-id uint) (required-vaccine-type (string-ascii 50)))
  (let
    (
      (vaccination-history (default-to (list) (map-get? pet-vaccination-history pet-id)))
      (compliance-period (default-to u0 (map-get? vaccine-compliance-periods required-vaccine-type)))
    )
    (ok {
      pet-id: pet-id,
      vaccine-type: required-vaccine-type,
      has-valid-vaccination: (> compliance-period u0),
      checked-at: stacks-block-height
    })
  )
)

;; Get counters
(define-read-only (get-counters)
  (ok {
    total-pets: (var-get pet-counter),
    total-vaccinations: (var-get vaccination-counter),
    total-certificates: (var-get certificate-counter)
  })
)

;; title: vaccination-tracker
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;


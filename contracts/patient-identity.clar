;; Patient Identity Contract
;; Securely manages patient information

(define-data-var admin principal tx-sender)

;; Map to store patient identities
(define-map patients principal
  {
    hash-id: (buff 32),  ;; Hashed identifier
    metadata-hash: (buff 32),  ;; Hash of encrypted metadata
    created-at: uint,
    updated-at: uint
  }
)

;; Map to track patient data versions
(define-map patient-versions {patient: principal, version: uint}
  {
    metadata-hash: (buff 32),
    timestamp: uint
  }
)

;; Counter for patient versions
(define-map version-counters principal uint)

;; Register a new patient (self-registration)
(define-public (register-patient (hash-id (buff 32)) (metadata-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? patients tx-sender)) (err u409))
    (map-set patients tx-sender
      {
        hash-id: hash-id,
        metadata-hash: metadata-hash,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (map-set version-counters tx-sender u1)
    (map-set patient-versions {patient: tx-sender, version: u1}
      {
        metadata-hash: metadata-hash,
        timestamp: block-height
      }
    )
    (ok true)
  )
)

;; Update patient information (only the patient can update their own info)
(define-public (update-patient-info (metadata-hash (buff 32)))
  (let (
    (patient-data (unwrap! (map-get? patients tx-sender) (err u404)))
    (current-version (default-to u0 (map-get? version-counters tx-sender)))
    (new-version (+ current-version u1))
  )
    (begin
      (map-set patients tx-sender
        (merge patient-data {
          metadata-hash: metadata-hash,
          updated-at: block-height
        })
      )
      (map-set version-counters tx-sender new-version)
      (map-set patient-versions {patient: tx-sender, version: new-version}
        {
          metadata-hash: metadata-hash,
          timestamp: block-height
        }
      )
      (ok new-version)
    )
  )
)

;; Get patient information (read-only)
(define-read-only (get-patient-info (patient principal))
  (map-get? patients patient)
)

;; Get specific version of patient data
(define-read-only (get-patient-version (patient principal) (version uint))
  (map-get? patient-versions {patient: patient, version: version})
)

;; Get current version number
(define-read-only (get-current-version (patient principal))
  (default-to u0 (map-get? version-counters patient))
)

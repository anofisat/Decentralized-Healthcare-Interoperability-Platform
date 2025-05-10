;; Consent Management Contract
;; Controls permissions for data sharing

;; Map to store patient consents
(define-map consents
  {patient: principal, provider: principal}
  {
    granted: bool,
    scope: (list 10 (string-utf8 50)),  ;; List of data types allowed
    expiration: uint,  ;; Block height when consent expires
    granted-at: uint
  }
)

;; Grant consent to a provider
(define-public (grant-consent
  (provider principal)
  (scope (list 10 (string-utf8 50)))
  (expiration uint))
  (begin
    (ok (map-set consents {patient: tx-sender, provider: provider}
      {
        granted: true,
        scope: scope,
        expiration: (+ block-height expiration),
        granted-at: block-height
      }
    ))
  )
)

;; Revoke consent from a provider
(define-public (revoke-consent (provider principal))
  (let ((consent-data (unwrap! (map-get? consents {patient: tx-sender, provider: provider}) (err u404))))
    (begin
      (ok (map-set consents {patient: tx-sender, provider: provider}
        (merge consent-data {
          granted: false
        })
      ))
    )
  )
)

;; Check if consent is valid
(define-read-only (is-consent-valid (patient principal) (provider principal) (data-type (string-utf8 50)))
  (let ((consent-data (map-get? consents {patient: patient, provider: provider})))
    (and
      (is-some consent-data)
      (unwrap-panic (get granted consent-data))
      (> (unwrap-panic (get expiration consent-data)) block-height)
      (is-some (index-of (unwrap-panic (get scope consent-data)) data-type))
    )
  )
)

;; Get consent details
(define-read-only (get-consent-details (patient principal) (provider principal))
  (map-get? consents {patient: patient, provider: provider})
)

;; Update consent scope
(define-public (update-consent-scope
  (provider principal)
  (scope (list 10 (string-utf8 50))))
  (let ((consent-data (unwrap! (map-get? consents {patient: tx-sender, provider: provider}) (err u404))))
    (begin
      (ok (map-set consents {patient: tx-sender, provider: provider}
        (merge consent-data {
          scope: scope
        })
      ))
    )
  )
)

;; Extend consent expiration
(define-public (extend-consent
  (provider principal)
  (additional-blocks uint))
  (let ((consent-data (unwrap! (map-get? consents {patient: tx-sender, provider: provider}) (err u404))))
    (begin
      (ok (map-set consents {patient: tx-sender, provider: provider}
        (merge consent-data {
          expiration: (+ (get expiration consent-data) additional-blocks)
        })
      ))
    )
  )
)

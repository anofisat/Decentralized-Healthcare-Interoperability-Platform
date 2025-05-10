;; Data Standardization Contract
;; Normalizes medical information formats

(define-data-var admin principal tx-sender)

;; Map to store supported data standards
(define-map data-standards (string-utf8 50)
  {
    version: (string-utf8 20),
    schema-hash: (buff 32),
    active: bool,
    created-at: uint
  }
)

;; Map to store data mappings between standards
(define-map standard-mappings
  {source: (string-utf8 50), target: (string-utf8 50)}
  {
    mapping-hash: (buff 32),
    created-at: uint
  }
)

;; Register a new data standard (admin only)
(define-public (register-standard (name (string-utf8 50)) (version (string-utf8 20)) (schema-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set data-standards name
      {
        version: version,
        schema-hash: schema-hash,
        active: true,
        created-at: block-height
      }
    ))
  )
)

;; Deactivate a data standard (admin only)
(define-public (deactivate-standard (name (string-utf8 50)))
  (let ((standard-data (unwrap! (map-get? data-standards name) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set data-standards name
        (merge standard-data {
          active: false
        })
      ))
    )
  )
)

;; Register a mapping between standards (admin only)
(define-public (register-mapping
  (source (string-utf8 50))
  (target (string-utf8 50))
  (mapping-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? data-standards source)) (err u404))
    (asserts! (is-some (map-get? data-standards target)) (err u404))
    (ok (map-set standard-mappings {source: source, target: target}
      {
        mapping-hash: mapping-hash,
        created-at: block-height
      }
    ))
  )
)

;; Get standard information
(define-read-only (get-standard (name (string-utf8 50)))
  (map-get? data-standards name)
)

;; Get mapping between standards
(define-read-only (get-mapping (source (string-utf8 50)) (target (string-utf8 50)))
  (map-get? standard-mappings {source: source, target: target})
)

;; Check if a standard is active
(define-read-only (is-standard-active (name (string-utf8 50)))
  (default-to false (get active (map-get? data-standards name)))
)

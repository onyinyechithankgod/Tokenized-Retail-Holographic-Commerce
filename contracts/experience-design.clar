;; Experience Design Contract
;; Manages holographic shopping experiences

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_EXPERIENCE (err u202))
(define-constant ERR_EXPERIENCE_EXISTS (err u203))

;; Data structures
(define-map holographic-experiences
  { experience-id: uint }
  {
    creator: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    immersion-level: uint,
    interaction-type: (string-ascii 50),
    created-at: uint,
    active: bool
  }
)

(define-map experience-ratings
  { experience-id: uint, user: principal }
  { rating: uint, feedback: (string-ascii 200) }
)

(define-map user-experiences
  { user: principal, experience-id: uint }
  { accessed-at: uint, duration: uint, completed: bool }
)

(define-data-var next-experience-id uint u1)

;; Public functions
(define-public (create-experience
  (name (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (immersion-level uint)
  (interaction-type (string-ascii 50))
)
  (let ((experience-id (var-get next-experience-id)))
    (asserts! (<= immersion-level u10) ERR_INVALID_EXPERIENCE)
    (map-set holographic-experiences
      { experience-id: experience-id }
      {
        creator: tx-sender,
        name: name,
        description: description,
        category: category,
        immersion-level: immersion-level,
        interaction-type: interaction-type,
        created-at: block-height,
        active: true
      }
    )
    (var-set next-experience-id (+ experience-id u1))
    (ok experience-id)
  )
)

(define-public (rate-experience (experience-id uint) (rating uint) (feedback (string-ascii 200)))
  (begin
    (asserts! (<= rating u5) ERR_INVALID_EXPERIENCE)
    (asserts! (>= rating u1) ERR_INVALID_EXPERIENCE)
    (map-set experience-ratings
      { experience-id: experience-id, user: tx-sender }
      { rating: rating, feedback: feedback }
    )
    (ok true)
  )
)

(define-public (access-experience (experience-id uint))
  (begin
    (map-set user-experiences
      { user: tx-sender, experience-id: experience-id }
      { accessed-at: block-height, duration: u0, completed: false }
    )
    (ok true)
  )
)

(define-public (complete-experience (experience-id uint) (duration uint))
  (begin
    (map-set user-experiences
      { user: tx-sender, experience-id: experience-id }
      { accessed-at: block-height, duration: duration, completed: true }
    )
    (ok true)
  )
)

(define-public (deactivate-experience (experience-id uint))
  (let ((experience (unwrap! (map-get? holographic-experiences { experience-id: experience-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator experience)) ERR_UNAUTHORIZED)
    (map-set holographic-experiences
      { experience-id: experience-id }
      (merge experience { active: false })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-experience (experience-id uint))
  (map-get? holographic-experiences { experience-id: experience-id })
)

(define-read-only (get-experience-rating (experience-id uint) (user principal))
  (map-get? experience-ratings { experience-id: experience-id, user: user })
)

(define-read-only (get-user-experience (user principal) (experience-id uint))
  (map-get? user-experiences { user: user, experience-id: experience-id })
)

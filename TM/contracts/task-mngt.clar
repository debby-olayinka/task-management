;; Define the contract
(define-constant contract-admin tx-sender)

;; Data structures
(define-data-var current-task-id uint u0)

(define-map tasks
  uint ;; task-id
  {
    client: principal,
    contractor: (optional principal),
    name: (string-utf8 100),
    details: (string-utf8 500),
    total-amount: uint,
    phase-count: uint,
    finished-phases: uint,
    is-finished: bool
  }
)

(define-map phase-info
  { task-id: uint, phase-id: uint }
  {
    details: (string-utf8 200),
    is-verified: bool,
    is-disbursed: bool
  }
)

;; Errors
(define-constant err-not-authorized (err u100))
(define-constant err-task-not-found (err u101))
(define-constant err-phase-not-found (err u102))
(define-constant err-invalid-contractor (err u103))
(define-constant err-phase-already-verified (err u104))
(define-constant err-phase-already-disbursed (err u105))
(define-constant err-task-already-finished (err u106))
(define-constant err-invalid-input (err u107))

;; Input validation helpers
(define-private (is-valid-string (str (string-utf8 500)))
  (> (len str) u0)
)

(define-private (is-valid-amount (amount uint))
  (> amount u0)
)

(define-private (is-valid-phase-count (count uint))
  (and (> count u0) (<= count u100))
)

(define-private (is-valid-phase-id (phase-id uint) (max-phases uint))
  (and (> phase-id u0) (<= phase-id max-phases))
)

;; Create a new task
(define-public (create-task (name (string-utf8 100)) (details (string-utf8 500)) (total-amount uint) (total-phases uint))
  (let ((new-task-id (+ (var-get current-task-id) u1)))
    (asserts! (is-eq tx-sender contract-admin) err-not-authorized)
    (asserts! (is-valid-string name) err-invalid-input)
    (asserts! (is-valid-string details) err-invalid-input)
    (asserts! (is-valid-amount total-amount) err-invalid-input)
    (asserts! (is-valid-phase-count total-phases) err-invalid-input)
    (map-set tasks new-task-id
      {
        client: tx-sender,
        contractor: none,
        name: name,
        details: details,
        total-amount: total-amount,
        phase-count: total-phases,
        finished-phases: u0,
        is-finished: false
      }
    )
    (var-set current-task-id new-task-id)
    (ok new-task-id)
  )
)

;; Assign a contractor to a task
(define-public (assign-contractor (tid uint) (contractor principal))
  (let ((task (map-get? tasks tid)))
    (asserts! (is-some task) err-task-not-found)
    (asserts! (is-eq (get client (unwrap-panic task)) tx-sender) err-not-authorized)
    (map-set tasks tid
      (merge (unwrap-panic task)
        {
          contractor: (some contractor)
        }
      )
    )
    (ok true)
  )
)

;; Submit a phase
(define-public (submit-phase (tid uint) (phase-id uint) (details (string-utf8 200)))
  (let ((task (map-get? tasks tid)))
    (asserts! (is-some task) err-task-not-found)
    (asserts! (is-eq (get contractor (unwrap-panic task)) (some tx-sender)) err-invalid-contractor)
    (asserts! (is-valid-string details) err-invalid-input)
    (asserts! (is-valid-phase-id phase-id (get phase-count (unwrap-panic task))) err-invalid-input)
    (map-set phase-info { task-id: tid, phase-id: phase-id }
      {
        details: details,
        is-verified: false,
        is-disbursed: false
      }
    )
    (ok true)
  )
)

;; Verify a phase
(define-public (verify-phase (tid uint) (phase-id uint))
  (let ((task (map-get? tasks tid))
        (milestone (map-get? phase-info { task-id: tid, phase-id: phase-id })))
    (asserts! (is-some task) err-task-not-found)
    (asserts! (is-some milestone) err-phase-not-found)
    (asserts! (is-eq (get client (unwrap-panic task)) tx-sender) err-not-authorized)
    (asserts! (is-valid-phase-id phase-id (get phase-count (unwrap-panic task))) err-invalid-input)
    (asserts! (not (get is-verified (unwrap-panic milestone))) err-phase-already-verified)
    (map-set phase-info { task-id: tid, phase-id: phase-id }
      (merge (unwrap-panic milestone)
        {
          is-verified: true
        }
      )
    )
    (map-set tasks tid
      (merge (unwrap-panic task)
        {
          finished-phases: (+ (get finished-phases (unwrap-panic task)) u1)
        }
      )
    )
    (ok true)
  )
)

;; Release payment for a phase
(define-public (release-payment (tid uint) (phase-id uint))
  (let ((task (map-get? tasks tid))
        (phase (map-get? phase-info { task-id: tid, phase-id: phase-id })))
    (asserts! (is-some task) err-task-not-found)
    (asserts! (is-some phase) err-phase-not-found)
    (asserts! (is-eq (get client (unwrap-panic task)) tx-sender) err-not-authorized)
    (asserts! (is-valid-phase-id phase-id (get phase-count (unwrap-panic task))) err-invalid-input)
    (asserts! (get is-verified (unwrap-panic phase)) err-phase-not-found)
    (asserts! (not (get is-disbursed (unwrap-panic phase))) err-phase-already-disbursed)
    (map-set phase-info { task-id: tid, phase-id: phase-id }
      (merge (unwrap-panic phase)
        {
          is-disbursed: true
        }
      )
    )
    (ok true)
  )
)

;; Mark task as finished
(define-public (complete-task (tid uint))
  (let ((task (map-get? tasks tid)))
    (asserts! (is-some task) err-task-not-found)
    (asserts! (is-eq (get client (unwrap-panic task)) tx-sender) err-not-authorized)
    (asserts! (not (get is-finished (unwrap-panic task))) err-task-already-finished)
    (asserts! (is-eq (get finished-phases (unwrap-panic task)) (get phase-count (unwrap-panic task))) err-not-authorized)
    (map-set tasks tid
      (merge (unwrap-panic task)
        {
          is-finished: true
        }
      )
    )
    (ok true)
  )
)

;; Helper function to get task details
(define-read-only (get-task-details (tid uint))
  (map-get? tasks tid)
)

;; Helper function to get phase details
(define-read-only (get-phase-details (tid uint) (phase-id uint))
  (map-get? phase-info { task-id: tid, phase-id: phase-id })
)
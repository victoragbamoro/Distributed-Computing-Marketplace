
;; title: Distributed-Computing-Marketplace

;; ========== Constant Definitions ==========
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-REGISTERED (err u102))
(define-constant ERR-INVALID-JOB (err u103))
(define-constant ERR-INVALID-BID (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-JOB-ALREADY-ASSIGNED (err u106))
(define-constant ERR-JOB-NOT-ASSIGNED (err u107))
(define-constant ERR-UNAUTHORIZED-COMPLETION (err u108))
(define-constant ERR-INVALID-PAYMENT (err u109))
(define-constant ERR-INVALID-RATING (err u110))
(define-constant ERR-DISPUTE-ALREADY-EXISTS (err u111))
(define-constant ERR-NOT-IN-DISPUTE (err u112))
(define-constant ERR-UNAUTHORIZED-RESOLVER (err u113))
(define-constant ERR-INVALID-PROPOSAL (err u114))
(define-constant ERR-PROPOSAL-ALREADY-VOTED (err u115))

;; Governance parameters
(define-constant GOVERNANCE-THRESHOLD u70) ;; 70% support required for proposals to pass
(define-constant DISPUTE-RESOLUTION-FEE u1000000) ;; in uSTX
(define-constant PLATFORM-FEE-PERCENTAGE u2) ;; 2% fee
(define-constant MIN-STAKE-AMOUNT u50000000) ;; 50 STX minimum stake for providers

;; ========== Data Maps and Variables ==========

;; Provider registry - stores information about computing resource providers
(define-map providers principal 
  {
    registered: bool,
    available: bool,
    resource-type: (string-utf8 50),    ;; e.g., "GPU", "CPU", "Storage"
    specs: (string-utf8 200),           ;; detailed specifications
    price-per-hour: uint,               ;; in micro-STX
    reputation-score: uint,             ;; out of 100
    total-ratings: uint,
    total-completed-jobs: uint,
    total-earnings: uint,
    staked-amount: uint,                ;; stake for commitment
    lightning-node-id: (optional (string-utf8 66))  ;; Lightning Network node ID
  }
)


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

;; Client registry - stores information about clients who need computing resources
(define-map clients principal
  {
    registered: bool,
    reputation-score: uint,            ;; out of 100
    total-ratings: uint,
    total-jobs-created: uint,
    total-jobs-completed: uint,
    total-spent: uint,
    lightning-node-id: (optional (string-utf8 66))  ;; Lightning Network node ID
  }
)

;; Job data structure - stores all jobs in the marketplace
(define-map jobs uint
  {
    client: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    resource-requirements: (string-utf8 200),
    payment-amount: uint,               ;; in micro-STX
    status: (string-utf8 20),           ;; "open", "assigned", "completed", "disputed", "cancelled"
    creation-time: uint,
    deadline: uint,
    provider: (optional principal),
    result-hash: (optional (buff 32)),  ;; hash of computation result
    verification-proof: (optional (buff 512)),  ;; proof of correct computation
    escrow-amount: uint,                ;; amount held in escrow
    dispute-resolution-votes: uint      ;; for governance resolution
  }
)

;; Bids placed on jobs
(define-map bids 
  {job-id: uint, bidder: principal} 
  {
    amount: uint,
    estimated-time: uint,
    proposal: (string-utf8 200),
    timestamp: uint
  }
)

;; Disputes tracking
(define-map disputes uint
  {
    job-id: uint,
    initiator: principal,
    reason: (string-utf8 500),
    evidence: (buff 64),
    status: (string-utf8 20),           ;; "open", "resolved", "client-favor", "provider-favor"
    created-at: uint,
    resolved-at: (optional uint)
  }
)

;; Reputation history
(define-map reputation-history 
  {user: principal, job-id: uint} 
  {
    rater: principal,
    rating: uint,                       ;; 1-5 stars
    comment: (string-utf8 200),
    timestamp: uint
  }
)

;; Governance proposals
(define-map governance-proposals uint
  {
    proposer: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    proposal-type: (string-utf8 30),    ;; "parameter-change", "feature-addition", "protocol-upgrade"
    parameter-key: (optional (string-utf8 50)),
    parameter-value: (optional uint),
    votes-for: uint,
    votes-against: uint,
    status: (string-utf8 20),           ;; "active", "passed", "rejected", "implemented"
    created-at: uint,
    ends-at: uint
  }
)
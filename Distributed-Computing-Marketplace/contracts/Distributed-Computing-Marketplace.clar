
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

;; Votes on governance proposals
(define-map proposal-votes 
  {proposal-id: uint, voter: principal} 
  {
    vote: bool,                         ;; true = for, false = against
    weight: uint,                       ;; based on reputation and stake
    timestamp: uint
  }
)

;; Lightning Network payment channels
(define-map payment-channels 
  {provider: principal, client: principal} 
  {
    channel-id: (buff 32),
    provider-node-id: (string-utf8 66),
    client-node-id: (string-utf8 66),
    capacity: uint,
    is-active: bool,
    created-at: uint
  }
)

;; Contract state variables
(define-data-var job-counter uint u0)
(define-data-var dispute-counter uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var total-platform-fees uint u0)
(define-data-var total-jobs-completed uint u0)
(define-data-var total-computation-time uint u0)

;; Get client details
(define-read-only (get-client (client-id principal))
  (default-to 
    {
      registered: false,
      reputation-score: u0,
      total-ratings: u0,
      total-jobs-created: u0,
      total-jobs-completed: u0,
      total-spent: u0,
      lightning-node-id: none
    }
    (map-get? clients client-id)
  )
)

;; Get job details
(define-read-only (get-job (job-id uint))
  (map-get? jobs job-id)
)

;; Helper function for get-job-bids
(define-private (check-and-add-bid (result (list 10 {job-id: uint, bidder: principal, amount: uint, estimated-time: uint, proposal: (string-utf8 200), timestamp: uint})) (current-job-id uint))
  result
)

;; Get dispute details
(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes dispute-id)
)

;; Get reputation rating for a job
(define-read-only (get-reputation-for-job (user principal) (job-id uint))
  (map-get? reputation-history {user: user, job-id: job-id})
)

;; Get governance proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? governance-proposals proposal-id)
)

;; Get vote on a proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes {proposal-id: proposal-id, voter: voter})
)

;; Get payment channel details
(define-read-only (get-payment-channel (provider principal) (client principal))
  (map-get? payment-channels {provider: provider, client: client})
)

;; Check if a user is registered as a client
(define-read-only (is-client-registered (client principal))
  (get registered (get-client client))
)

;; Register as a client
(define-public (register-client (lightning-node-id (optional (string-utf8 66))))
  (let
    ((client-exists (is-client-registered tx-sender)))
    
    (asserts! (not client-exists) ERR-ALREADY-REGISTERED)
    
    ;; Map the client data
    (map-set clients tx-sender
      {
        registered: true,
        reputation-score: u80,  ;; Start with neutral reputation (80/100)
        total-ratings: u0,
        total-jobs-created: u0,
        total-jobs-completed: u0,
        total-spent: u0,
        lightning-node-id: lightning-node-id
      }
    )
    
    (ok true)
  )
)

;; Update client details
(define-public (update-client-details (lightning-node-id (optional (string-utf8 66))))
  (let
    ((client-data (get-client tx-sender)))
    
    (asserts! (get registered client-data) ERR-NOT-REGISTERED)
    
    (map-set clients tx-sender
      (merge client-data 
        {
          lightning-node-id: lightning-node-id
        }
      )
    )
    
    (ok true)
  )
)

;; Rate a client after job completion
(define-public (rate-client (job-id uint) (rating uint) (comment (string-utf8 200)))
  (let
    ((job-data (unwrap! (get-job job-id) ERR-INVALID-JOB))
     (client (get client job-data))
     (client-data (get-client client)))
    
    ;; Ensure sender is the job provider
    (asserts! (is-eq (some tx-sender) (get provider job-data)) ERR-NOT-AUTHORIZED)
    
    
    
    ;; Ensure rating is valid (1-5)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
    
    ;; Record the rating
    (map-set reputation-history
      {user: client, job-id: job-id}
      {
        rater: tx-sender,
        rating: rating,
        comment: comment,
        timestamp: stacks-block-height
      }
    )
    
    ;; Update client reputation
    (let
      ((current-total (* (get reputation-score client-data) (get total-ratings client-data)))
       (new-total-ratings (+ (get total-ratings client-data) u1))
       (new-total-score (+ current-total (* rating u20)))  ;; Scale 1-5 to 0-100
       (new-reputation (/ new-total-score new-total-ratings)))
      
      (map-set clients client
        (merge client-data
          {
            reputation-score: new-reputation,
            total-ratings: new-total-ratings
          }
        )
      )
      
      (ok true)
    )
  )
)

;; NEW: Verification results
(define-map verification-results
  {job-id: uint, verifier: principal}
  {
    result: bool,                      ;; true = verified correct, false = incorrect
    verification-time: uint,
    reward-amount: uint,
    verification-proof: (buff 64),
    comments: (string-utf8 200)
  }
)

;; NEW: Provider subscription tiers
(define-map subscription-tiers uint
  {
    name: (string-utf8 50),
    description: (string-utf8 200),
    cost-per-month: uint,
    benefits: (string-utf8 500),
    max-concurrent-jobs: uint,
    priority-bidding: bool,
    reduced-fees: uint                  ;; Fee reduction percentage
  }
)

;; NEW: SLA (Service Level Agreement) definitions
(define-map service-level-agreements uint
  {
    name: (string-utf8 50),
    description: (string-utf8 200),
    uptime-requirement: uint,           ;; Percentage
    response-time-max: uint,            ;; In blocks
    penalty-amount: uint,               ;; In micro-STX
    bonus-amount: uint                  ;; In micro-STX
  }
)

;; NEW: Job SLA tracking
(define-map job-sla-tracking
  {job-id: uint}
  {
    sla-id: uint,
    actual-uptime: uint,
    actual-response-time: uint,
    sla-met: bool,
    penalty-applied: uint,
    bonus-applied: uint
  }
)

;; NEW: Get verification result
(define-read-only (get-verification-result (job-id uint) (verifier principal))
  (map-get? verification-results {job-id: job-id, verifier: verifier})
)

;; NEW: Get subscription tier details
(define-read-only (get-subscription-tier (tier-id uint))
  (map-get? subscription-tiers tier-id)
)

;; NEW: Get SLA details
(define-read-only (get-service-level-agreement (sla-id uint))
  (map-get? service-level-agreements sla-id)
)

;; NEW: Get job SLA tracking
(define-read-only (get-job-sla-tracking (job-id uint))
  (map-get? job-sla-tracking {job-id: job-id})
)
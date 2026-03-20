package ph.edu.neu.library.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "visit_logs")
public class VisitLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VisitReason reason;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public VisitLog() {}

    public VisitLog(User user, VisitReason reason) {
        this.user = user;
        this.reason = reason;
    }

    // ── Getters ──

    public Long getId() { return id; }

    public User getUser() { return user; }

    public VisitReason getReason() { return reason; }

    public Instant getCreatedAt() { return createdAt; }
}

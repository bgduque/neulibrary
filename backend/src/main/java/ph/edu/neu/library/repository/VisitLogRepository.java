package ph.edu.neu.library.repository;

import java.time.Instant;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ph.edu.neu.library.model.VisitLog;
import ph.edu.neu.library.model.VisitReason;

public interface VisitLogRepository extends JpaRepository<VisitLog, Long> {

    long countByCreatedAtBetween(Instant start, Instant end);

    long countByReasonAndCreatedAtBetween(VisitReason reason, Instant start, Instant end);

    @Query("""
            SELECT v.user.collegeOffice, COUNT(v) FROM VisitLog v \
            WHERE v.createdAt BETWEEN :start AND :end \
            GROUP BY v.user.collegeOffice \
            ORDER BY COUNT(v) DESC\
            """)
    List<Object[]> countByCollegeBetween(@Param("start") Instant start,
                                         @Param("end") Instant end);

    List<VisitLog> findByCreatedAtBetweenOrderByCreatedAtDesc(Instant start, Instant end);

    List<VisitLog> findByUserIdOrderByCreatedAtDesc(Long userId);

    void deleteByUserId(Long userId);
}

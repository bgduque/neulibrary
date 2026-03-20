package ph.edu.neu.library.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;
import ph.edu.neu.library.dto.CheckInRequest;
import ph.edu.neu.library.dto.StatsResponse;
import ph.edu.neu.library.dto.VisitDto;
import ph.edu.neu.library.model.User;
import ph.edu.neu.library.model.VisitLog;
import ph.edu.neu.library.model.VisitReason;
import ph.edu.neu.library.repository.VisitLogRepository;

@Service
public class VisitService {

    private final VisitLogRepository visitLogRepository;
    private final UserService userService;

    public VisitService(VisitLogRepository visitLogRepository, UserService userService) {
        this.visitLogRepository = visitLogRepository;
        this.userService = userService;
    }

    public void checkIn(Long userId, CheckInRequest request) {
        User user = userService.getById(userId);

        if (user.isBlocked()) {
            throw new IllegalStateException("Access Denied. Please contact the Library Admin.");
        }
        if (!user.isSetupComplete()) {
            throw new IllegalStateException("Please complete your profile setup first.");
        }

        visitLogRepository.save(new VisitLog(user, request.reason()));
    }

    public StatsResponse getStats(LocalDate from, LocalDate to) {
        Instant start = from.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant end = to.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();

        long total = visitLogRepository.countByCreatedAtBetween(start, end);

        Map<String, Long> reasonBreakdown = new LinkedHashMap<>();
        for (VisitReason reason : VisitReason.values()) {
            long count = visitLogRepository.countByReasonAndCreatedAtBetween(reason, start, end);
            reasonBreakdown.put(reason.getDisplayName(), count);
        }

        Map<String, Long> collegeBreakdown = new LinkedHashMap<>();
        for (Object[] row : visitLogRepository.countByCollegeBetween(start, end)) {
            String college = row[0] != null ? (String) row[0] : "Unspecified";
            Long count = (Long) row[1];
            collegeBreakdown.put(college, count);
        }

        return new StatsResponse(total, reasonBreakdown, collegeBreakdown);
    }

    public java.util.List<VisitDto> getVisits(LocalDate from, LocalDate to) {
        Instant start = from.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant end = to.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();

        return visitLogRepository.findByCreatedAtBetweenOrderByCreatedAtDesc(start, end).stream()
                .map(v -> new VisitDto(
                        v.getId(),
                        v.getUser().getFullName(),
                        v.getUser().getEmail(),
                        v.getUser().getCollegeOffice(),
                        v.getReason().getDisplayName(),
                        v.getCreatedAt()
                ))
                .toList();
    }
}

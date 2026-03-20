package ph.edu.neu.library.dto;

import java.time.Instant;

public record VisitDto(
        Long id,
        String userName,
        String userEmail,
        String collegeOffice,
        String reason,
        Instant createdAt
) {}

package ph.edu.neu.library.dto;

import java.util.Map;

public record StatsResponse(
        long totalVisitors,
        Map<String, Long> reasonBreakdown,
        Map<String, Long> collegeBreakdown
) {}

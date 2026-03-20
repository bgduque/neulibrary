package ph.edu.neu.library.dto;

public record AuthResponse(
        String token,
        UserProfileDto user
) {}

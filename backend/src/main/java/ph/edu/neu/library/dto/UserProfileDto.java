package ph.edu.neu.library.dto;

import ph.edu.neu.library.model.User;

public record UserProfileDto(
        Long id,
        String email,
        String fullName,
        String photoUrl,
        String role,
        String collegeOffice,
        boolean setupComplete,
        boolean blocked
) {
    public static UserProfileDto from(User user) {
        return new UserProfileDto(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhotoUrl(),
                user.getRole().name(),
                user.getCollegeOffice(),
                user.isSetupComplete(),
                user.isBlocked()
        );
    }
}

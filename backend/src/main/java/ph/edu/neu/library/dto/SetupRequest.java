package ph.edu.neu.library.dto;

import jakarta.validation.constraints.NotBlank;

public record SetupRequest(
        @NotBlank String collegeOffice
) {}

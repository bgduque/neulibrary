package ph.edu.neu.library.dto;

import jakarta.validation.constraints.NotNull;
import ph.edu.neu.library.model.UserRole;

public record RoleRequest(
        @NotNull UserRole role
) {}

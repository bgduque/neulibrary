package ph.edu.neu.library.dto;

import jakarta.validation.constraints.NotNull;
import ph.edu.neu.library.model.VisitReason;

public record CheckInRequest(
        @NotNull VisitReason reason
) {}

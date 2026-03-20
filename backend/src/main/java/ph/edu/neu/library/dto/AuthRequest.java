package ph.edu.neu.library.dto;

import jakarta.validation.constraints.AssertTrue;

public record AuthRequest(
        String idToken,
        String accessToken
) {
    /** At least one token must be supplied. */
    @AssertTrue(message = "Either idToken or accessToken must be provided")
    public boolean isValid() {
        return (idToken != null && !idToken.isBlank())
            || (accessToken != null && !accessToken.isBlank());
    }
}

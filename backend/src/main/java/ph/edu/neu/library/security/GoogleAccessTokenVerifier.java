package ph.edu.neu.library.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * Verifies Google OAuth <b>access tokens</b> by calling Google's tokeninfo and
 * userinfo endpoints.  This is the web-platform fallback for cases where the
 * frontend cannot obtain a Google <em>ID</em> token (GIS Token Client flow).
 */
@Component
public class GoogleAccessTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(GoogleAccessTokenVerifier.class);

    private static final String TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo?access_token=";
    private static final String USERINFO_URL  = "https://www.googleapis.com/oauth2/v3/userinfo";

    private final String clientId;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public GoogleAccessTokenVerifier(@Value("${app.google.client-id}") String clientId) {
        this.clientId = clientId;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Lightweight container for the verified Google user info obtained from an
     * access token.
     */
    public record GoogleUserInfo(String googleId, String email, String name, String pictureUrl) {}

    /**
     * Verify the given access token with Google and return user info.
     *
     * @return user info, or {@code null} if the token is invalid / doesn't
     *         belong to our client.
     */
    public GoogleUserInfo verify(String accessToken) {
        try {
            // 1. Validate the token and check the audience.
            HttpRequest tokenReq = HttpRequest.newBuilder()
                    .uri(URI.create(TOKENINFO_URL + accessToken))
                    .timeout(Duration.ofSeconds(5))
                    .GET()
                    .build();

            HttpResponse<String> tokenResp =
                    httpClient.send(tokenReq, HttpResponse.BodyHandlers.ofString());

            if (tokenResp.statusCode() != 200) {
                log.warn("tokeninfo returned {}", tokenResp.statusCode());
                return null;
            }

            JsonNode tokenInfo = objectMapper.readTree(tokenResp.body());
            log.info("tokeninfo response: {}", tokenResp.body());

            // The "azp" (authorized party) or "aud" (audience) field must match
            // our client ID.  GIS Token Client may populate these differently.
            String azp = tokenInfo.path("azp").asText("");
            String aud = tokenInfo.path("aud").asText("");
            if (!clientId.equals(azp) && !clientId.equals(aud)) {
                log.warn("Access token audience mismatch: expected={}, azp={}, aud={}", clientId, azp, aud);
                return null;
            }

            String email = tokenInfo.path("email").asText(null);
            String googleId = tokenInfo.path("sub").asText(null);
            if (email == null || googleId == null) {
                log.warn("tokeninfo missing email or sub");
                return null;
            }

            // 2. Get profile info (name, picture) from userinfo endpoint.
            HttpRequest userInfoReq = HttpRequest.newBuilder()
                    .uri(URI.create(USERINFO_URL))
                    .header("Authorization", "Bearer " + accessToken)
                    .timeout(Duration.ofSeconds(5))
                    .GET()
                    .build();

            HttpResponse<String> userInfoResp =
                    httpClient.send(userInfoReq, HttpResponse.BodyHandlers.ofString());

            String name = null;
            String pictureUrl = null;
            if (userInfoResp.statusCode() == 200) {
                JsonNode userInfo = objectMapper.readTree(userInfoResp.body());
                name = userInfo.path("name").asText(null);
                pictureUrl = userInfo.path("picture").asText(null);
            }

            return new GoogleUserInfo(googleId, email, name, pictureUrl);
        } catch (Exception e) {
            log.error("Failed to verify access token", e);
            return null;
        }
    }
}

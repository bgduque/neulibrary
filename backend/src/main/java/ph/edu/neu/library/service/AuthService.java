package ph.edu.neu.library.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import ph.edu.neu.library.dto.AuthRequest;
import ph.edu.neu.library.dto.AuthResponse;
import ph.edu.neu.library.dto.UserProfileDto;
import ph.edu.neu.library.model.User;
import ph.edu.neu.library.model.UserRole;
import ph.edu.neu.library.repository.UserRepository;
import ph.edu.neu.library.security.GoogleAccessTokenVerifier;
import ph.edu.neu.library.security.GoogleTokenVerifier;
import ph.edu.neu.library.security.JwtTokenProvider;
import java.time.Instant;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final GoogleTokenVerifier googleTokenVerifier;
    private final GoogleAccessTokenVerifier googleAccessTokenVerifier;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    private final String allowedDomain;
    private final Set<String> superAdminEmails;

    public AuthService(GoogleTokenVerifier googleTokenVerifier,
                       GoogleAccessTokenVerifier googleAccessTokenVerifier,
                       JwtTokenProvider jwtTokenProvider,
                       UserRepository userRepository,
                       @Value("${app.allowed-domain}") String allowedDomain,
                       @Value("${app.super-admin-email}") String superAdminEmails) {
        this.googleTokenVerifier = googleTokenVerifier;
        this.googleAccessTokenVerifier = googleAccessTokenVerifier;
        this.jwtTokenProvider = jwtTokenProvider;
        this.userRepository = userRepository;
        this.allowedDomain = allowedDomain;
        this.superAdminEmails = Arrays.stream(superAdminEmails.split(","))
                .map(String::trim)
                .map(String::toLowerCase)
                .collect(Collectors.toSet());
    }

    /**
     * Verify the Google token (ID token or access token), upsert the user,
     * and return an application JWT.
     */
    public AuthResponse authenticate(AuthRequest request) {
        String email;
        String googleId;
        String fullName;
        String photoUrl;

        if (request.idToken() != null && !request.idToken().isBlank()) {
            // ── Path A: ID token (mobile / browsers that support it) ──
            log.info("Authenticating with ID token");
            GoogleIdToken.Payload payload = googleTokenVerifier.verify(request.idToken());
            if (payload == null) {
                throw new IllegalArgumentException("Invalid Google ID token");
            }
            email    = payload.getEmail();
            googleId = payload.getSubject();
            fullName = (String) payload.get("name");
            photoUrl = (String) payload.get("picture");
        } else {
            // ── Path B: Access token (web / GIS Token Client flow) ──
            log.info("Authenticating with access token");
            GoogleAccessTokenVerifier.GoogleUserInfo info =
                    googleAccessTokenVerifier.verify(request.accessToken());
            if (info == null) {
                throw new IllegalArgumentException("Invalid Google access token");
            }
            email    = info.email();
            googleId = info.googleId();
            fullName = info.name();
            photoUrl = info.pictureUrl();
        }

        if (email == null || !email.endsWith("@" + allowedDomain)) {
            throw new IllegalArgumentException("Only @" + allowedDomain + " emails are allowed");
        }

        User user = userRepository.findByGoogleId(googleId).orElseGet(() -> {
            User newUser = new User(googleId, email,
                    fullName != null ? fullName : email,
                    photoUrl);
            return userRepository.save(newUser);
        });

        // Update profile fields if they changed on Google's side.
        boolean changed = false;
        if (fullName != null && !fullName.equals(user.getFullName())) {
            user.setFullName(fullName);
            changed = true;
        }
        if (photoUrl != null && !photoUrl.equals(user.getPhotoUrl())) {
            user.setPhotoUrl(photoUrl);
            changed = true;
        }
        // Auto-promote designated super admins.
        if (superAdminEmails.contains(email.toLowerCase()) && user.getRole() != UserRole.SUPER_ADMIN) {
            user.setRole(UserRole.SUPER_ADMIN);
            changed = true;
        }
        if (changed) {
            user.setUpdatedAt(Instant.now());
            userRepository.save(user);
        }

        String jwt = jwtTokenProvider.generateToken(
                user.getId(), user.getEmail(), user.getRole().name());

        return new AuthResponse(jwt, UserProfileDto.from(user));
    }
}

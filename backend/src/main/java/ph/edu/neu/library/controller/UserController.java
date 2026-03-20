package ph.edu.neu.library.controller;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ph.edu.neu.library.dto.SetupRequest;
import ph.edu.neu.library.dto.UserProfileDto;
import ph.edu.neu.library.service.UserService;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileDto> getProfile(Authentication auth) {
        Long userId = Long.valueOf(auth.getName());
        return ResponseEntity.ok(userService.getProfile(userId));
    }

    @PutMapping("/me/setup")
    public ResponseEntity<UserProfileDto> completeSetup(
            Authentication auth,
            @Valid @RequestBody SetupRequest request) {
        Long userId = Long.valueOf(auth.getName());
        return ResponseEntity.ok(userService.completeSetup(userId, request));
    }
}

package ph.edu.neu.library.controller;

import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.core.Authentication;
import ph.edu.neu.library.dto.BlockRequest;
import ph.edu.neu.library.dto.RoleRequest;
import ph.edu.neu.library.dto.StatsResponse;
import ph.edu.neu.library.dto.UserProfileDto;
import ph.edu.neu.library.dto.VisitDto;
import ph.edu.neu.library.service.UserService;
import ph.edu.neu.library.service.VisitService;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final VisitService visitService;
    private final UserService userService;

    public AdminController(VisitService visitService, UserService userService) {
        this.visitService = visitService;
        this.userService = userService;
    }

    @GetMapping("/stats")
    public ResponseEntity<StatsResponse> getStats(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(visitService.getStats(from, to));
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserProfileDto>> searchUsers(
            @RequestParam(defaultValue = "") String q) {
        return ResponseEntity.ok(userService.searchUsers(q));
    }

    @GetMapping("/visits")
    public ResponseEntity<List<VisitDto>> searchVisits(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(visitService.getVisits(from, to));
    }

    @PutMapping("/users/{userId}/block")
    public ResponseEntity<UserProfileDto> setBlocked(
            @PathVariable Long userId,
            @Valid @RequestBody BlockRequest request) {
        return ResponseEntity.ok(userService.setBlocked(userId, request.blocked()));
    }

    @PutMapping("/users/{userId}/role")
    public ResponseEntity<UserProfileDto> setRole(
            @PathVariable Long userId,
            @Valid @RequestBody RoleRequest request,
            Authentication auth) {
        Long requesterId = Long.valueOf(auth.getName());
        return ResponseEntity.ok(userService.setRole(userId, request.role(), requesterId));
    }

    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Void> deleteUser(
            @PathVariable Long userId,
            Authentication auth) {
        Long requesterId = Long.valueOf(auth.getName());
        userService.deleteUser(userId, requesterId);
        return ResponseEntity.noContent().build();
    }
}

package ph.edu.neu.library.controller;

import java.util.Map;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ph.edu.neu.library.dto.CheckInRequest;
import ph.edu.neu.library.service.VisitService;

@RestController
@RequestMapping("/api/visits")
public class VisitController {

    private final VisitService visitService;

    public VisitController(VisitService visitService) {
        this.visitService = visitService;
    }

    @PostMapping
    public ResponseEntity<Map<String, String>> checkIn(
            Authentication auth,
            @Valid @RequestBody CheckInRequest request) {
        Long userId = Long.valueOf(auth.getName());
        visitService.checkIn(userId, request);
        return ResponseEntity.ok(Map.of("message", "Welcome to NEU Library!"));
    }
}

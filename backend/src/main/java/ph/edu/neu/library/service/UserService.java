package ph.edu.neu.library.service;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ph.edu.neu.library.dto.SetupRequest;
import ph.edu.neu.library.dto.UserProfileDto;
import ph.edu.neu.library.model.User;
import ph.edu.neu.library.model.UserRole;
import ph.edu.neu.library.repository.UserRepository;
import ph.edu.neu.library.repository.VisitLogRepository;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final VisitLogRepository visitLogRepository;

    public UserService(UserRepository userRepository, VisitLogRepository visitLogRepository) {
        this.userRepository = userRepository;
        this.visitLogRepository = visitLogRepository;
    }

    public User getById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    public UserProfileDto getProfile(Long userId) {
        return UserProfileDto.from(getById(userId));
    }

    public UserProfileDto completeSetup(Long userId, SetupRequest request) {
        User user = getById(userId);
        user.setCollegeOffice(request.collegeOffice());
        user.setSetupComplete(true);
        user.setUpdatedAt(Instant.now());
        return UserProfileDto.from(userRepository.save(user));
    }

    public List<UserProfileDto> searchUsers(String query) {
        return userRepository
                .findByEmailContainingIgnoreCaseOrFullNameContainingIgnoreCase(query, query)
                .stream()
                .map(UserProfileDto::from)
                .toList();
    }

    public UserProfileDto setBlocked(Long userId, boolean blocked) {
        User user = getById(userId);
        user.setBlocked(blocked);
        user.setUpdatedAt(Instant.now());
        return UserProfileDto.from(userRepository.save(user));
    }

    public UserProfileDto setRole(Long userId, UserRole newRole, Long requesterId) {
        User requester = getById(requesterId);
        if (requester.getRole() != UserRole.SUPER_ADMIN) {
            throw new IllegalStateException("Only a Super Admin can change user roles.");
        }
        if (newRole == UserRole.SUPER_ADMIN) {
            throw new IllegalArgumentException("Cannot assign SUPER_ADMIN role.");
        }
        User user = getById(userId);
        if (user.getRole() == UserRole.SUPER_ADMIN) {
            throw new IllegalStateException("Cannot change the role of a Super Admin.");
        }
        user.setRole(newRole);
        user.setUpdatedAt(Instant.now());
        return UserProfileDto.from(userRepository.save(user));
    }

    @Transactional
    public void deleteUser(Long userId, Long requesterId) {
        User requester = getById(requesterId);
        if (requester.getRole() != UserRole.SUPER_ADMIN && requester.getRole() != UserRole.ADMIN) {
            throw new IllegalStateException("Only an Admin can delete users.");
        }
        User user = getById(userId);
        if (user.getRole() == UserRole.SUPER_ADMIN) {
            throw new IllegalStateException("Cannot delete a Super Admin.");
        }
        
        visitLogRepository.deleteByUserId(user.getId());
        userRepository.delete(user);
    }
}

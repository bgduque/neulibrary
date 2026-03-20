package ph.edu.neu.library.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ph.edu.neu.library.model.User;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByGoogleId(String googleId);

    Optional<User> findByEmail(String email);

    List<User> findByEmailContainingIgnoreCaseOrFullNameContainingIgnoreCase(
            String email, String fullName);
}

package ph.edu.neu.library.service;

import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

/**
 * Handles file uploads/downloads against a GCP Cloud Storage bucket.
 */
@Service
public class StorageService {

    private final Storage storage;
    private final String bucket;

    public StorageService(@Value("${app.storage.bucket}") String bucket) {
        this.storage = StorageOptions.getDefaultInstance().getService();
        this.bucket = bucket;
    }

    /**
     * Upload a file and return its public URL.
     */
    public String upload(String folder, MultipartFile file) throws IOException {
        String filename = folder + "/" + UUID.randomUUID() + "-" + file.getOriginalFilename();
        BlobId blobId = BlobId.of(bucket, filename);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId)
                .setContentType(file.getContentType())
                .build();
        storage.create(blobInfo, file.getBytes());
        return String.format("https://storage.googleapis.com/%s/%s", bucket, filename);
    }

    /**
     * Delete a blob by its full object name (folder/filename).
     */
    public boolean delete(String objectName) {
        return storage.delete(BlobId.of(bucket, objectName));
    }
}

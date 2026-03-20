package ph.edu.neu.library.model;

public enum VisitReason {
    READING("Reading"),
    RESEARCH("Research"),
    COMPUTER_USE("Computer Use"),
    STUDYING("Studying");

    private final String displayName;

    VisitReason(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

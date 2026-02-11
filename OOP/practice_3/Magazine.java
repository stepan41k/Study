public class Magazine extends LibraryItem {
    private int issueNumber;

    public Magazine(String title, String author, int issueNumber) {
        super(title, author);
        this.issueNumber = issueNumber;
    }

    public int getIssueNumber() {
        return issueNumber;
    }

    public void setIssueNumber(int issueNumber) {
        this.issueNumber = issueNumber;
    }

    @Override
    public void showInfo() {
        System.out.println("[Журнал] Название: \"" + getTitle() + "\", Автор: " + getAuthor() + ", Выпуск №" + issueNumber);
    }
}
public class DigitalBook extends Book {
    private double fileSize;

    public DigitalBook(String title, String author, int pages, double fileSize) {
        super(title, author, pages);
        this.fileSize = fileSize;
    }

    public double getFileSize() {
        return fileSize;
    }

    public void setFileSize(double fileSize) {
        this.fileSize = fileSize;
    }

    @Override
    public void showInfo() {
        System.out.println("[Электронная книга] Название: \"" + getTitle() + "\", Автор: " + getAuthor()
                + ", Страниц: " + getPages() + ", Размер файла: " + fileSize + " MB");
    }
}
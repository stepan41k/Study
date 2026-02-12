public class Book extends LibraryItem {
    private int pages;

    public Book(String title, String author, int pages) {
        super(title, author);
        this.pages = pages;
    }

    public int getPages() {
        return pages;
    }

    public void setPages(int pages) {
        this.pages = pages;
    }

    @Override
    public void showInfo() {
        System.out.println("[Книга] Название книги: \"" + getTitle() + "\", Автор книги: " + getAuthor() + ", Страниц: " + pages);
    }
}
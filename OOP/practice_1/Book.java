public class Book {
    private String title;
    private String author;
    private int pages;
    private String genre;

    public Book(String title, String author, int pages, String genre) {
        this.title = title;
        this.author = author;
        this.pages = pages;
        this.genre = genre;
    }

    public void display_info() {
        System.out.println("Information about book");
        System.out.println("Title: " + title);
        System.out.println("Author: " + author);
        System.out.println("Pages count: " + pages);
        System.out.println("Genre: " + genre);
        System.out.println("");
    }

    public boolean is_long() {
        return pages > 300;
    }

    public boolean is_short() {
        return pages < 100;
    }

    public void setGenre(String newGenre) {
        this.genre = newGenre;
        System.out.println("Genre has been changed to: " + newGenre);
    }

    public void addPages(int additionalPages) {
        this.pages += additionalPages;
        System.out.println("Added " + additionalPages + " pages. Current count of pages: " + this.pages);
    }

    public void updateAuthor(String newAuthor) {
        this.author = newAuthor;
        System.out.println("Author changed to: " + newAuthor);
    }

    public String toFormattedString() {
        return "\"" + title + "\" - " + author + " (" + genre + ", " + pages + " pages)";
    }

    public String getTitle() { return title; }
    public String getAuthor() { return author; }
    public int getPages() { return pages; }
    public String getGenre() { return genre; }

    
    public static void main(String[] args) {
        Book book = new Book("Война и мир", "Лев Толстой", 1225, "Роман");

        book.display_info();

        System.out.println("Is long? " + (book.is_long() ? "Yes" : "No"));

        System.out.println("Is short? " + (book.is_short() ? "Yes" : "No"));

        System.out.println("Format: " + book.toFormattedString());

        System.out.println();

        book.setGenre("Исторический роман");
        book.updateAuthor("Л.Н. Толстой");
        book.addPages(50);

        System.out.println();

        book.display_info();
        System.out.println("Format: " + book.toFormattedString());

        System.out.println("\n Second book \n");

        Book shortBook = new Book("Старик и море", "Эрнест Хемингуэй", 80, "Повесть");
        shortBook.display_info();
        System.out.println("Is long? " + (shortBook.is_long() ? "Yes" : "No"));
        System.out.println("Is short? " + (shortBook.is_short() ? "Yes" : "No"));
        System.out.println("Format: " + shortBook.toFormattedString());
    }
}
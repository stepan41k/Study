public class Main {
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

        System.out.println("\nSecond book \n");

        Book shortBook = new Book("Старик и море", "Эрнест Хемингуэй", 80, "Повесть");
        shortBook.display_info();
        System.out.println("Is long? " + (shortBook.is_long() ? "Yes" : "No"));
        System.out.println("Is short? " + (shortBook.is_short() ? "Yes" : "No"));
        System.out.println("Format: " + shortBook.toFormattedString());
    }
}
public class Main {
    public static void main(String[] args) {
        //1
        Book book1 = new Book("Война и мир", "Лев Толстой", 1225);
        Book book2 = new Book("Преступление и наказание", "Фёдор Достоевский", 671);
        Magazine mag1 = new Magazine("National Geographic", "Редакция NG", 256);
        Magazine mag2 = new Magazine("Forbes", "Редакция Forbes", 102);
        DigitalBook dBook1 = new DigitalBook("Java. Полное руководство", "Герберт Шилдт", 1486, 45.7);
        DigitalBook dBook2 = new DigitalBook("Clean Code", "Роберт Мартин", 464, 12.3);

        //2
        System.out.println("ПОЛИМОРФИЗМ: вызов showInfo()");
        LibraryItem[] allItems = {book1, book2, mag1, mag2, dBook1, dBook2};

        //3
        for (LibraryItem item : allItems) {
            item.showInfo();
        }
        System.out.println();


        Library<LibraryItem> generalLibrary = new Library<>();
        generalLibrary.addItem(book1);
        generalLibrary.addItem(mag1);
        generalLibrary.addItem(dBook1);
        generalLibrary.addItem(mag2);
        System.out.println();
        generalLibrary.showAllItems();
        System.out.println();

        //4
        System.out.println("БИБЛИОТЕКА С АРЕНДОЙ (только книги)");
        BorrowableLibrary<Book> borrowableLibrary = new BorrowableLibrary<>();
        borrowableLibrary.addItem(book1);
        borrowableLibrary.addItem(book2);
        borrowableLibrary.addItem(dBook1);
        borrowableLibrary.addItem(dBook2);
        System.out.println();


        //5
        borrowableLibrary.showAllItems();
        System.out.println();


        System.out.println("Берём книги в аренду");
        borrowableLibrary.borrowItem(book1);
        borrowableLibrary.borrowItem(dBook1);
        System.out.println();


        System.out.println("Повторная попытка аренды");
        borrowableLibrary.borrowItem(book1);
        System.out.println();


        borrowableLibrary.showAllItems();
        System.out.println();


        System.out.println("Возвращаем книгу");
        borrowableLibrary.returnItem(book1);
        System.out.println();


        System.out.println("Итоговый статус");
        borrowableLibrary.showAllItems();
    }
}
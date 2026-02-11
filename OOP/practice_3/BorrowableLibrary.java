import java.util.HashMap;
import java.util.Map;

public class BorrowableLibrary<T> extends Library<T> {
    private Map<T, Boolean> borrowedItems;

    public BorrowableLibrary() {
        super();
        this.borrowedItems = new HashMap<>();
    }

    @Override
    public void addItem(T item) {
        super.addItem(item);
        borrowedItems.put(item, false);
    }

    @Override
    public void removeItem(T item) {
        super.removeItem(item);
        borrowedItems.remove(item);
    }

    public void borrowItem(T item) {
        if (!items.contains(item)) {
            System.out.println("Элемент не найден в библиотеке.");
            return;
        }
        if (borrowedItems.getOrDefault(item, false)) {
            System.out.println("Элемент уже взят в аренду.");
        } else {
            borrowedItems.put(item, true);
            System.out.println("Элемент успешно взят в аренду.");
        }
    }

    public void returnItem(T item) {
        if (!items.contains(item)) {
            System.out.println("Элемент не найден в библиотеке.");
            return;
        }
        if (!borrowedItems.getOrDefault(item, false)) {
            System.out.println("Элемент не был в аренде.");
        } else {
            borrowedItems.put(item, false);
            System.out.println("Элемент успешно возвращён.");
        }
    }

    @Override
    public void showAllItems() {
        if (items.isEmpty()) {
            System.out.println("Библиотека пуста.");
            return;
        }
        System.out.println("Список элементов (с статусом аренды)");
        for (T item : items) {
            if (item == null) {
                System.out.println("null");
            } else if (item instanceof LibraryItem li) {
                li.showInfo();
            } else {
                System.out.println(item.toString());
            }
            boolean isBorrowed = borrowedItems.getOrDefault(item, false);
            System.out.println("   Статус: " + (isBorrowed ? "⛔ В аренде" : "✅ Доступен"));
        }
        System.out.println("------------------------");
    }
}
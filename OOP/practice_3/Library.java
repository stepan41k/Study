import java.util.ArrayList;
import java.util.List;

public class Library<T> {
    protected List<T> items;

    public Library() {
        this.items = new ArrayList<>();
    }

    public void addItem(T item) {
        items.add(item);
        System.out.println("Элемент добавлен в библиотеку.");
    }

    public void removeItem(T item) {
        if (items.remove(item)) {
            System.out.println("Элемент удалён из библиотеки.");
        } else {
            System.out.println("Элемент не найден в библиотеке.");
        }
    }

    public void showAllItems() {
        if (items.isEmpty()) {
            System.out.println("Библиотека пуста.");
            return;
        }
        System.out.println("Список элементов библиотеки");
        for (T item : items) {
            if (item == null) {
                System.out.println("null");
            } else if (item instanceof LibraryItem li) {
                li.showInfo();
            } else {
                System.out.println(item.toString());
            }
        }
        System.out.println("----------------------------------");
    }

    public List<T> getItems() {
        return items;
    }
}
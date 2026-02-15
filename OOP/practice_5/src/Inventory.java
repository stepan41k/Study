import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Inventory — инвентарь персонажа.
 * Владеет объектами InventoryItem (композиция): создаёт и удаляет их сам.
 * Наружу возвращает только неизменяемое представление списка.
 */
public class Inventory {

    private final List<InventoryItem> items = new ArrayList<>();

    public void addItem(Item item, int quantity) {
        if (item == null) {
            throw new IllegalArgumentException("Item не может быть null.");
        }
        if (quantity < 1) {
            throw new IllegalArgumentException("Количество должно быть >= 1.");
        }

        for (InventoryItem inv : items) {
            if (inv.getItem().getId().equals(item.getId())) {
                inv.setQuantity(inv.getQuantity() + quantity);
                return;
            }
        }
        // Inventory сам создаёт InventoryItem — это композиция
        items.add(new InventoryItem(item, quantity));
    }

    public boolean removeItem(String itemId) {
        return items.removeIf(inv -> inv.getItem().getId().equals(itemId));
    }

    public void changeQuantity(String itemId, int newQuantity) {
        for (int i = 0; i < items.size(); i++) {
            InventoryItem inv = items.get(i);
            if (inv.getItem().getId().equals(itemId)) {
                if (newQuantity < 1) {
                    items.remove(i);
                } else {
                    inv.setQuantity(newQuantity);
                }
                return;
            }
        }
        System.out.println("Предмет с id '" + itemId + "' не найден в инвентаре.");
    }

    public double getTotalValue() {
        double total = 0;
        for (InventoryItem inv : items) {
            total += inv.getTotalValue();
        }
        return total;
    }

    public List<InventoryItem> getItems() {
        return Collections.unmodifiableList(items);
    }

    public void printInventory() {
        if (items.isEmpty()) {
            System.out.println("  Инвентарь пуст.");
            return;
        }
        for (InventoryItem inv : items) {
            System.out.println("  " + inv);
        }
        System.out.println("  Общая ценность: " + getTotalValue());
    }
}
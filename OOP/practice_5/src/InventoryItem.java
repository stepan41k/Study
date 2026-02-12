public class InventoryItem {

    private final Item item;   // агрегация: Item существует независимо
    private int quantity;

    /**
     * Пакетный доступ — создавать InventoryItem может только Inventory.
     */
    InventoryItem(Item item, int quantity) {
        if (item == null) {
            throw new IllegalArgumentException("Item не может быть null.");
        }
        if (quantity < 1) {
            throw new IllegalArgumentException("Количество должно быть >= 1.");
        }
        this.item = item;
        this.quantity = quantity;
    }

    public Item getItem() {
        return item;
    }

    public int getQuantity() {
        return quantity;
    }

    /**
     * Пакетный доступ — менять количество может только Inventory.
     */
    void setQuantity(int quantity) {
        if (quantity < 1) {
            throw new IllegalArgumentException("Количество должно быть >= 1.");
        }
        this.quantity = quantity;
    }

    /**
     * Суммарная ценность = baseValue * quantity.
     */
    public double getTotalValue() {
        return item.getBaseValue() * quantity;
    }

    @Override
    public String toString() {
        return "InventoryItem{item=" + item.getName()
                + ", quantity=" + quantity
                + ", totalValue=" + getTotalValue() + "}";
    }
}
public class InventoryItem {

    private final Item item;
    private int quantity;

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

    void setQuantity(int quantity) {
        if (quantity < 1) {
            throw new IllegalArgumentException("Количество должно быть >= 1.");
        }
        this.quantity = quantity;
    }

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
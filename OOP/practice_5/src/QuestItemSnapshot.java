public class QuestItemSnapshot {

    private final String itemName;
    private final int quantity;
    private final double baseValue;

    QuestItemSnapshot(String itemName, int quantity, double baseValue) {
        this.itemName = itemName;
        this.quantity = quantity;
        this.baseValue = baseValue;
    }

    public String getItemName() {
        return itemName;
    }

    public int getQuantity() {
        return quantity;
    }

    public double getBaseValue() {
        return baseValue;
    }

    @Override
    public String toString() {
        return "QuestItemSnapshot{name='" + itemName
                + "', qty=" + quantity
                + "', baseValue=" + baseValue + "}";
    }
}
public class Item {

    private final String id;
    private final String name;
    private final double baseValue;

    public Item(String id, String name, double baseValue) {
        if (id == null || id.isBlank()) {
            throw new IllegalArgumentException("ID предмета не может быть пустым или null.");
        }
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Имя предмета не может быть пустым или null.");
        }
        if (baseValue < 0) {
            throw new IllegalArgumentException("Базовое значение не может быть отрицательным.");
        }
        this.id = id;
        this.name = name;
        this.baseValue = baseValue;
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public double getBaseValue() {
        return baseValue;
    }

    @Override
    public String toString() {
        return "Item{id='" + id + "', name='" + name + "', baseValue=" + baseValue + "}";
    }
}
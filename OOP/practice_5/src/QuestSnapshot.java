import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * QuestSnapshot — снимок состояния персонажа на момент начала квеста.
 * Фиксирует данные (копии), чтобы дальнейшие изменения персонажа не влияли на снимок.
 * QuestItemSnapshot — часть композиции: существует только внутри QuestSnapshot.
 */
public class QuestSnapshot {

    public enum Status {
        STARTED, IN_PROGRESS, COMPLETED, FAILED
    }

    private final String questId;
    private final String characterId;
    private final String characterName;
    private final int strength;
    private final int agility;
    private final int intelligence;
    private final List<QuestItemSnapshot> itemSnapshots;
    private Status status;

    public QuestSnapshot(String questId, Character character) {
        if (questId == null || questId.isBlank()) {
            throw new IllegalArgumentException("Quest ID не может быть пустым.");
        }
        if (character == null) {
            throw new IllegalArgumentException("Character не может быть null.");
        }

        this.questId = questId;
        this.characterId = character.getId();
        this.characterName = character.getName();
        this.strength = character.getStrength();
        this.agility = character.getAgility();
        this.intelligence = character.getIntelligence();
        this.status = Status.STARTED;

        // Копируем данные инвентаря — не ссылки!
        List<QuestItemSnapshot> snapshots = new ArrayList<>();
        for (InventoryItem invItem : character.getInventory().getItems()) {
            snapshots.add(new QuestItemSnapshot(
                    invItem.getItem().getName(),
                    invItem.getQuantity(),
                    invItem.getItem().getBaseValue()
            ));
        }
        this.itemSnapshots = Collections.unmodifiableList(snapshots);
    }

    public String getQuestId() {
        return questId;
    }

    public String getCharacterId() {
        return characterId;
    }

    public String getCharacterName() {
        return characterName;
    }

    public int getStrength() {
        return strength;
    }

    public int getAgility() {
        return agility;
    }

    public int getIntelligence() {
        return intelligence;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public List<QuestItemSnapshot> getItemSnapshots() {
        return itemSnapshots;
    }

    public void printSnapshot() {
        System.out.println("=== Снимок квеста '" + questId + "' ===");
        System.out.println("Персонаж: " + characterName + " (id=" + characterId + ")");
        System.out.println("Статус: " + status);
        System.out.println("Характеристики: STR=" + strength + ", AGI=" + agility + ", INT=" + intelligence);
        System.out.println("Предметы на момент начала квеста:");
        if (itemSnapshots.isEmpty()) {
            System.out.println("  (нет предметов)");
        } else {
            for (QuestItemSnapshot snap : itemSnapshots) {
                System.out.println("  " + snap);
            }
        }
        System.out.println("================================");
    }
}
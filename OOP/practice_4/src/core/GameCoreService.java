package src.core;

public class GameCoreService {

    public void applyTick(Character c) {
        System.out.println("\n[CORE TICK] Processing: " + c.getName());
        // Пример: проверяем alive (package-private доступ)
        if (c.alive) {
            System.out.println("  " + c.getName() + " is alive. Status OK.");
        } else {
            System.out.println("  " + c.getName() + " is dead. Skipping.");
        }
        Character.coreEvents++;
    }

    public void revive(Character c) {
        System.out.println("\n[CORE] Reviving " + c.getName() + "...");
        c.reviveForCore(50); // package-private метод
        Character.coreEvents++;
    }

    public void balance(Character c) {
        System.out.println("\n[CORE] Balancing damage for " + c.getName() + "...");
        c.setDamageForCore(25); // package-private метод
        Character.coreEvents++;
    }

    public void printCoreDebug(Character c) {
        System.out.println("\n[CORE DEBUG] " + c.getName());
        System.out.println("  alive (package-private) = " + c.alive);
        System.out.println("  coreEvents (package-private static) = " + Character.coreEvents);
        System.out.println("  Full info: " + c);
        Character.coreEvents++;
    }
}
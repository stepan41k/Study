package src.app;

import src.core.Character;
import src.core.BossCharacter;
import src.core.GameCoreService;

public class Main {
    public static void main(String[] args) {

        System.out.println("========================================");
        System.out.println("  Game: " + Character.GAME_NAME);
        System.out.println("========================================");

        // --- Создание персонажей ---
        System.out.println("\n--- Creating characters ---");
        Character warrior = new Character("Warrior", 100, 20, 1);
        Character mage = new Character("Mage", 80, 30, 1);
        BossCharacter dragon = new BossCharacter("Dragon", 500, 50, 10);

        System.out.println(warrior);
        System.out.println(mage);
        System.out.println(dragon);
        System.out.println("Total created: " + Character.getCreatedCharacters());

        // --- Нанесение урона ---
        System.out.println("\n--- Combat: dealing damage ---");
        warrior.takeDamage(30);
        System.out.println("Warrior health: " + warrior.getHealth());

        mage.takeDamage(50);
        System.out.println("Mage health: " + mage.getHealth());

        // --- Лечение ---
        System.out.println("\n--- Healing ---");
        warrior.heal(20);
        System.out.println("Warrior health after heal: " + warrior.getHealth());

        // --- Убийство персонажа ---
        System.out.println("\n--- Killing mage ---");
        mage.takeDamage(100); // должен умереть
        System.out.println("Mage alive? " + mage.isAlive());
        System.out.println("Mage health: " + mage.getHealth());

        // --- Оживление через GameCoreService ---
        System.out.println("\n--- Core service: revive ---");
        GameCoreService coreService = new GameCoreService();
        coreService.revive(mage);
        System.out.println("Mage alive after revive? " + mage.isAlive());
        System.out.println("Mage health after revive: " + mage.getHealth());

        // --- Core tick ---
        coreService.applyTick(warrior);
        coreService.applyTick(mage);

        // --- Балансировка ---
        coreService.balance(warrior);

        // --- Debug ---
        coreService.printCoreDebug(warrior);

        // --- Босс: накопление ярости ---
        System.out.println("\n--- Boss: rage mechanics ---");
        dragon.gainRage(40);
        dragon.gainRage(30);
        dragon.unleashRage(); // не хватит (70/100)

        dragon.gainRage(50);  // станет 100 (или больше, обрежется)
        dragon.unleashRage(); // теперь хватит!
        System.out.println(dragon);

        // --- Итоги ---
        System.out.println("\n========================================");
        System.out.println("  Total characters created: " + Character.getCreatedCharacters());
        System.out.println("  Game: " + Character.GAME_NAME);
        System.out.println("========================================");

        // =============================================================
        // НЕ ДОЛЖНО КОМПИЛИРОВАТЬСЯ (раскомментируйте для проверки)
        // =============================================================

        // --- Доступ к private полям ---
        // System.out.println(warrior.health);   // ERROR: health has private access
        // System.out.println(warrior.damage);   // ERROR: damage has private access

        // --- Вызов private методов ---
        // warrior.die();                        // ERROR: die() has private access
        // warrior.logPrivate("test");           // ERROR: logPrivate() has private access

        // --- Доступ к package-private полю из другого пакета ---
        // System.out.println(warrior.alive);    // ERROR: alive is not public; cannot be accessed from outside package

        // --- Вызов package-private методов из другого пакета ---
        // warrior.reviveForCore(100);           // ERROR: reviveForCore() is not public
        // warrior.setDamageForCore(999);        // ERROR: setDamageForCore() is not public

        // --- Вызов protected методов из другого пакета (не наследник) ---
        // warrior.addLevel(5);                  // ERROR: addLevel() has protected access
        // warrior.empower(99);                  // ERROR: empower() has protected access

        // --- Доступ к private static полю ---
        // System.out.println(Character.createdCharacters); // ERROR: createdCharacters has private access

        // --- Доступ к package-private static полю ---
        // System.out.println(Character.coreEvents);        // ERROR: coreEvents is not public
    }
}
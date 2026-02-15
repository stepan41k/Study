public class Main {

    public static void main(String[] args) {

        System.out.println("===== 1. Создаём предметы =====");
        Item sword = new Item("item_01", "Меч Пламени", 25.0);
        Item shield = new Item("item_02", "Щит Дуба", 15.0);
        Item potion = new Item("item_03", "Зелье Силы", 10.0);
        Item ring = new Item("item_04", "Кольцо Мудрости", 30.0);

        System.out.println(sword);
        System.out.println(shield);
        System.out.println(potion);
        System.out.println(ring);

        System.out.println();
        System.out.println("===== 2. Создаём персонажа =====");
        Character hero = new Character("char_01", "Арагорн");
        System.out.println(hero);

        System.out.println();
        System.out.println("===== 3. Добавляем предметы в инвентарь =====");
        hero.addItem(sword, 1);
        hero.addItem(shield, 1);
        hero.addItem(potion, 3);
        hero.addItem(ring, 1);
        hero.printInventory();

        System.out.println();
        System.out.println("===== 4. Применяем эффекты предметов =====");

        EffectPolicy noEffect = new NoEffect();
        EffectPolicy strengthBuff = new BuffEffect("strength", 1.0);
        EffectPolicy intelligenceBuff = new BuffEffect("intelligence", 1.5);

        noEffect.apply(hero, shield);        
        strengthBuff.apply(hero, potion);  
        intelligenceBuff.apply(hero, ring);

        System.out.println();
        System.out.println("Персонаж после эффектов:");
        System.out.println(hero);

        System.out.println();
        System.out.println("===== 5. Фиксируем состояние квеста =====");
        QuestSnapshot quest = new QuestSnapshot("quest_dragon_01", hero);
        quest.printSnapshot();

        System.out.println();
        System.out.println("===== 6. Изменяем инвентарь и характеристики ПОСЛЕ снимка =====");
        hero.removeItem("item_03");               
        hero.addItem(sword, 2);                   
        hero.setStrength(hero.getStrength() + 50);
        hero.changeQuantity("item_04", 5);         

        System.out.println();
        System.out.println("Персонаж ПОСЛЕ изменений:");
        System.out.println(hero);
        hero.printInventory();

        System.out.println();
        System.out.println("===== 7. Убеждаемся, что снимок квеста НЕ изменился =====");
        quest.printSnapshot();

        System.out.println();
        System.out.println("===== 8. Подключаем источники способностей (агрегация) =====");

        AbilitySource itemSource = new ItemAbilitySource(0.5);
        AbilitySource skillSource = new SkillAbilitySource(2.0);

        hero.addAbilitySource(itemSource);
        hero.addAbilitySource(skillSource);

        System.out.println("Источники способностей подключены.");
        System.out.println("Сила способностей от предметов: " + itemSource.getAbilityPower(hero));
        System.out.println("Сила способностей от навыков:   " + skillSource.getAbilityPower(hero));
        System.out.println("Общая сила способностей:        " + hero.getTotalAbilityPower());

        System.out.println();
        System.out.println("Финальное состояние персонажа:");
        System.out.println(hero);

        System.out.println();
        System.out.println("===== Бонус: эффект применяется к другому персонажу =====");
        Character mage = new Character("char_02", "Гэндальф");
        mage.addItem(ring, 2);
        intelligenceBuff.apply(mage, ring);
        System.out.println(mage);
    }
}
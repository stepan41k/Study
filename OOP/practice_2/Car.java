public class Car extends AbstractVehicle implements ElectricVehicle {

    public Car(String model, double speed) {
        super(model, speed);
    }

    @Override
    public void start() {
        System.out.println("Машина завелась");
    }

    @Override
    public void stop() {
        System.out.println("Машина остановилась");
    }

    @Override
    public void chargeBattery() {
        System.out.println("Машина подключена к зарядке");
    }
}
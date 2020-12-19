// ref https://tronscan.org/#/contract/THnSDgi6Do7Kvqhys7PndZvPVGzGRN4Y7c/code

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract SantaClaus {
    address internal santaClaus;

    event onSantaTransferred(address indexed previousSanta, address indexed newSanta);
    constructor() public {
        santaClaus = msg.sender;
    }
    modifier onlySanta() {
        require(msg.sender == santaClaus);
        _;
    }
    function reassignSanta(address _newSanta) public onlySanta {
        require(_newSanta != address(0));
        emit onSantaTransferred(santaClaus, _newSanta);
        santaClaus = _newSanta;
    }
}

contract Random {
    uint internal saltForRandom;

    function _rand() internal returns (uint256) {
        uint256 lastBlockNumber = block.number - 1;

        uint256 hashVal = uint256(blockhash(lastBlockNumber));

        // This turns the input data into a 100-sided die
        // by dividing by ceil(2 ^ 256 / 100).
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

        saltForRandom += uint256(msg.sender) % 100 + uint256(uint256(hashVal) / factor);

        return saltForRandom;
    }

    function _randRange(uint256 min, uint256 max) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_rand()))) % (max - min + 1) + min;
    }

    function _randChance(uint percent) internal returns (bool) {
        return _randRange(0, 100) < percent;
    }

    function _now() internal view returns (uint256) {
        return now;
    }
}

contract JustTron is SantaClaus, Random{
    using SafeMath for uint256;

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable private reindeerFood;
    address payable private sleighRepair;

    mapping(address => User) public users;


    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public elf_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public ChristmasElfs; // 5 топовых участника в день - берется с накопленого в день пула

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _reindeerFood,
                address payable _sleighRepair) public {

        santaClaus = msg.sender;

        reindeerFood = _reindeerFood;
        sleighRepair = _sleighRepair;

        // Ежедневные комиссионные, основанные на ежедневном доходе партнеров, для каждого прямого партнера активирован 1 уровень, максимум 20 уровней, см. Ниже
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5); // 15

        // Ежедневный рейтинг лучших пулов 3% от ВСЕХ депозитов, отведенных в пуле, каждые 24 часа 10% пула распределяется среди 10 лучших спонсоров по объему.
        elf_bonuses.push(30);
        elf_bonuses.push(20);
        elf_bonuses.push(15);
        elf_bonuses.push(10);
        elf_bonuses.push(9);
        elf_bonuses.push(5);
        elf_bonuses.push(5);
        elf_bonuses.push(3);
        elf_bonuses.push(2);
        elf_bonuses.push(1); // 10


        cycles.push(1e11);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(2e12);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function setStablesDeer(address payable _newStable) public onlySanta {
        require(_newStable != address(0));
        reindeerFood = _newStable;
    }

    function setSleighAccount(address payable _newSleighRepair) public onlySanta {
        require(_newSleighRepair != address(0));
        sleighRepair = _newSleighRepair;
    }

    // изменение линий
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != santaClaus && (users[_upline].deposit_time > 0 || _upline == santaClaus)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++; // увеличение структуры пригласившего

                _upline = users[_upline].upline;
            }
        }
    }

    // метод внесения депозита
    // проверяет доступный ввод исходя из возможного депозита по циклу
    // начисляет награду пригласившему - 10%
    // доабвляет гаргарду в пул лидеров
    // отправляет комиссию в фонд и админам
    //
    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == santaClaus, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount"); // min 100 TRX

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10; // начисление 10% прямого бонуса вышестоящему участнику - 10% Прямая комиссия

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount); // наполнение пула

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        reindeerFood.transfer(_amount / 20);
        sleighRepair.transfer(_amount / 20);
    }

    // 3% с каждого депозита отстетивагются в пул лидеров
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100; //  Ежедневный рейтинг лучших пулов 3% от ВСЕХ депозитов, отведенных в пуле, каждые 24 часа 10% пула распределяется среди 4 лучших спонсоров по объему.⠀

        address upline = users[_addr].upline;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            if(ChristmasElfs[i] == upline) break;

            if(ChristmasElfs[i] == address(0)) {
                ChristmasElfs[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][ChristmasElfs[i]]) {
                for(uint8 j = i + 1; j < elf_bonuses.length; j++) {
                    if(ChristmasElfs[j] == upline) {
                        for(uint8 k = j; k <= elf_bonuses.length; k++) {
                            ChristmasElfs[k] = ChristmasElfs[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(elf_bonuses.length - 1); j > i; j--) {
                    ChristmasElfs[j] = ChristmasElfs[j - 1];
                }

                ChristmasElfs[i] = upline;

                break;
            }
        }
    }

    // начисление реферальных вознаграждений линий в структуре
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break; // не для админа

            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100; // начисление бонуса комиссионого 30-3%(20 уровней)

                users[up].match_bonus += bonus; // здесь кучастнику происхоит сумирование бонусов в соответствие с

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    // метод накапливает 10 лидерам их награды и очищает список
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10; // 10%  - Ежедневный рейтинг лучших пулов 3% от ВСЕХ депозитов, отведенных в пуле, каждые 24 часа 10% пула распределяется среди 10 лучших спонсоров по объему.⠀

        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            if(ChristmasElfs[i] == address(0)) break;

            uint256 win = draw_amount * elf_bonuses[i] / 100;

            users[ChristmasElfs[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(ChristmasElfs[i], win);
        }

        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            ChristmasElfs[i] = address(0);
        }
    }

    function deposit(address _upline) payable public {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() public {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender); // текущий депозит и макс вывод от депозита

        require(users[msg.sender].payouts < max_payout, "Full payouts"); // ывел весь депозит

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }

        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");

        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    // максимальный доход 400 %
    function maxPayoutOf(uint256 _amount) pure public returns(uint256) {
        return _amount * 40 / 10; // 350% для изменения цикла
    }

    //возвращает текущий депозит и максимальный доход за вычетом выводов и наград для адреса
    function payoutOf(address _addr) view public returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100)
            + (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 500)
            - users[_addr].deposit_payouts;  // 1.2% пассив каждый день

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function userInfo(address _addr) view public returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view public returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view public returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][ChristmasElfs[0]]);
    }

    // озвращает инфо о 10 адресах оидерах и их балансах
    function poolTopInfo() view public returns(address[10] memory addrs, uint256[10] memory deps) {
        for(uint8 i = 0; i < elf_bonuses.length; i++) {
            if(ChristmasElfs[i] == address(0)) break;

            addrs[i] = ChristmasElfs[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][ChristmasElfs[i]];
        }
    }

    function getStablesDeer() public view onlySanta returns (address) {
        return reindeerFood;
    }

    function getSleighAccount() public view onlySanta returns (address) {
        return sleighRepair;
    }

}
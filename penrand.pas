[inherit ('montype'),
 environment ('monrand')]

module penrand;

const
  maxrandomspells = 7;

type
  RandREC = RECORD
    Name          :String;  (* The name of this type of random monster *)
    BaseHealth    :INTEGER; (* The base health for this random type *)
    RandomHealth  :INTEGER; (* The level health for this type *)
    BaseDamage    :INTEGER; (* The base damage of this type *)
    RandomDamage  :INTEGER; (* The random damage of this type *)
    LevelDamage   :INTEGER; (* The level damage *)
    Armor         :INTEGER; (* What percent armor this type of random has *)
    SpellArmor    :INTEGER; (* Spell armor for this type *)
    MoveSpeed     :INTEGER; (* How fast is this random *)
    AttackSpeed   :INTEGER; (* attack speed ... *)
    Kind          :INTEGER; (* What type of random is it *)
    Experience    :INTEGER; (* How much experience does it give when killed *)
    Gold          :INTEGER; (* What is the max amount of gold it carrries *)
    MinLevel      :INTEGER; (* At what level do they start appearing *)
    HealSpeed     :INTEGER; (* How fast does itheal *)
    Spell	  :ARRAY [1..MaxRandomSpells] of INTEGER; (* spells it has *)
    LevelHealth   :INTEGER;
    Extra1, Extra2:INTEGER;
    Group         :INTEGER; (* What group does it belong to *)
    PursuitChance :INTEGER; (* How often does it follow *)
    WeaponUse     :INTEGER;  (* What is the name of its weapon *)
    LevelWeaponUse:INTEGER;
    Weapon        :INTEGER;
    Object        :INTEGER; (* What object does it drop when it dies *)
    Sayings       :ARRAY [1..10] of Saying; (* What can it say *)
    BaseMana,
    LevelMana     :INTEGER;
    Size          :INTEGER;
  END;

[external] function getrand(randnum : integer; var rand : randrec;
                    silent : BYTE_BOOL := false) : BYTE_BOOL; extern;

[external] function saverand(randnum : integer; var rand : randrec;
                    silent : BYTE_BOOL := false) : BYTE_BOOL; extern;

END.

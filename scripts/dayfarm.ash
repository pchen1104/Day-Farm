// Maximizes adventures, farms volcano, and puts on nightcap.
// By pchen and stewchen

import <minevolcano.ash>

boolean AUTO_BUY = true;
boolean AUTO_PULL = false;

record itemQ {
	item it;
	int q;
	int lack;
	int purchase;
};
boolean reqPurchase = false;
int reqPulls = 0;
int reqMeat = 0;
itemQ [string] diet;

void selectItems() {
	diet["foodP"] = new itemQ( $item[ sleazy hi mein ], 3 , 0 , 0 );

	if(inebriety_limit() == 14) {
		diet["drinkP"] = new itemQ( $item[ perfect mimosa ], 4 , 0 , 0 );
		diet["drinkS"] = new itemQ( $item[ sacramento wine ], 2 , 0 , 0 );
	} else {
		diet["drinkP"] = new itemQ( $item[ perfect mimosa ], 6 , 0 , 0 );
		diet["drinkS"] = new itemQ( $item[ sacramento wine ], 1 , 0 , 0 );
	}

	diet["spleenP"] = new itemQ( $item[ powdered gold ], 3 , 0 , 0 );
	diet["spleenS"] = new itemQ( $item[ carrot juice ], 1 , 0 , 0 );

	diet["nightcap"] = new itemQ( $item[ bucket of wine ], 1 , 0 , 0 );
}

// check if consumption all at 0
boolean checkFullness() {
	if(my_fullness() != 0 || my_inebriety() != 0 || my_spleen_use() != 0) {
		return false;
	}
	return true;
}


void getMilk() {
	take_stash(closet_amount($item[milk of magnesium]), $item[milk of magnesium]);
	int x = item_amount($item[milk of magnesium]);
	if(x < 2 && !in_hardcore()) {
		int y = storage_amount($item[milk of magnesium]);
		if(x + y < 2) {
			if(AUTO_BUY || user_confirm((2 - y) * mall_price($item[milk of magnesium]) + " meat required for milk purchase. Confirm?")) {
				if(!can_interact()) {
					buy_using_storage(2 - y, $item[ milk of magnesium ]);
				} else {
					buy(2 - y, $item[ milk of magnesium ]);
				}
			}
			if(!AUTO_PULL || user_confirm(y + " pulls for milk of magnesium. Confirm pulls?")) {
				take_storage(y, $item[milk of magnesium]);
			}
		}
	}
}

boolean checkLacking() {
	boolean lacking = false;

	foreach key in diet {
		int n = item_amount(diet[key].it);
		if(n < diet[key].q) {
			n += closet_amount(diet[key].it);
			if(n < diet[key].q) {
				lacking = true;
				diet[key].lack = diet[key].q - n;
				reqPulls += diet[key].q - n;

				if(!can_interact()) {
					n += storage_amount(diet[key].it);
					if(n < diet[key].q) {
						diet[key].purchase = diet[key].q - n;
						reqPurchase = true;
					}
				} else {
					diet[key].purchase = diet[key].q - n;
					reqPurchase = true;
				} 
			}
		}
	}
	return lacking;
}

void checkPrice() {
	foreach key in diet {
		if(diet[key].purchase != 0) {
			reqMeat += diet[key].purchase * mall_price(diet[key].it);
		}
	}
}

boolean purchase() {
	if(!reqPurchase) {
		return true;
	}

	if(!AUTO_BUY) {
		checkPrice();
		if(!user_confirm(reqMeat + " meat required. Confirm purchase?")) {
			return false;
		}
	}

	foreach key in diet {
		if(diet[key].purchase != 0) {
			if(!can_interact()) {
				buy_using_storage(diet[key].purchase, diet[key].it);
			} else {
				buy(diet[key].purchase, diet[key].it);
			}
		}
	}
	return true;
}

void pull() {
	foreach key in diet {
		if(diet[key].lack != 0) {
			take_storage(diet[key].lack, diet[key].it);
		}
	}
}

void consume() {
	foreach key in diet {
		if(key == "nightcap") continue;

		string itemType = item_type(diet[key].it);
		switch (itemType) {
			case "food": 
				eat(diet[key].q, diet[key].it); 
				break;
			case "booze": 
				drink(diet[key].q, diet[key].it);
				break;
			default:
				chew(diet[key].q, diet[key].it); 
		}
	}
}

void diet() {
	if(!checkFullness()) {
		print("Fullness/Drunkness/Spleen not at 0.");
		print("Terminated.");
		return;
	}

	getMilk();
	selectItems();
	if(checkLacking()) {
		if(in_hardcore()) {
			print("Insufficient items.");
			print("Terminated.");
			return;
		}

		if(!can_interact() && pulls_remaining() < reqPulls) {
			print("Insufficient pulls remaining.");
			return;
		}
		
		if(!can_interact()) {
			if(AUTO_PULL || user_confirm(reqPulls + " pulls required. Confirm Pull?")) {
				if(!purchase()) {
					print("Terminated.");
					return;
				}
				pull();
			} else {
				print("Terminated.");
				return;
			}
		} else {
			purchase();
		}
	}

	if(have_effect($effect[ Ode to Booze ]) < inebriety_limit()) {
		if (!use_skill(2, $skill[ The Ode to Booze ])) {
			if(!user_confirm((inebriety_limit() - have_effect($effect[ Ode to Booze ])) + " more turns of Ode for max adv. Continue?")) {
				print("Terminated.");
			}
		}
	}
	if(have_effect($effect[ got milk ]) < fullness_limit() ) {
		use(2, $item[ milk of magnesium ]);
	}

	consume();
}

void nightcap() {
	if(have_effect($effect[ Ode to Booze ]) < inebriety_limit()) {
		if (!use_skill(1, $skill[ The Ode to Booze ])) {
			if(!user_confirm((inebriety_limit() - have_effect($effect[ Ode to Booze ])) + " more turns of Ode for max adv. Continue?")) {
				print("Terminated.");
			}
		}
	}
	selectItems();
	overdrink(1, diet["nightcap"].it);
}

void manageVolcanoEntry() {
	item volcanoTicket = $item[ one-day ticket to That 70s Volcano];
	if (item_amount(volcanoTicket) == 0) {
		buy(1, volcanoTicket);
	}
	use(1, volcanoTicket);

	if ( have_outfit( "Disco Outfit" ) ) {
		outfit( "Disco Outfit" );

		// Get Volcoino
		visit_url("place.php?whichplace=airport_hot&action=airport4_zone1");
		visit_url("choice.php?whichchoice=1090&option=7");
	} else {
		print( "You don't have the custom Disco Outfit outfit set up." );
	}
}

void main() {
	diet();

	manageVolcanoEntry();

	if ( have_outfit( "Volcano Mining" ) ) {
    	outfit( "Volcano Mining" );
	} else {
   		print( "You don't have the custom Volcano Mining outfit set up." );
	}

	main@minevolcano(my_adventures());
	nightcap();

    maximize("adv", false);
}

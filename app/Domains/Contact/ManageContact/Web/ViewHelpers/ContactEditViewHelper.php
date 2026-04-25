<?php

namespace App\Domains\Contact\ManageContact\Web\ViewHelpers;

use App\Models\Contact;
use App\Models\User;
use App\Models\Vault;

class ContactEditViewHelper
{
    public static function data(Vault $vault, Contact $contact, User $user): array
    {
        $account = $vault->account;

        $genders = $account->genders()->orderBy('name', 'asc')->get();
        $genderCollection = $genders->map(function ($gender) use ($contact) {
            return [
                'id' => $gender->id,
                'name' => $gender->name,
                'selected' => $gender->id === $contact->gender_id ? true : false,
            ];
        });

        return [
            'contact' => [
                'id' => $contact->id,
                'name' => $contact->name,
                'first_name' => $contact->first_name,
                'last_name' => $contact->last_name,
                'middle_name' => $contact->middle_name,
                'nickname' => $contact->nickname,
                'maiden_name' => $contact->maiden_name,
                'gender_id' => $contact->gender_id,
                'prefix' => $contact->prefix,
                'suffix' => $contact->suffix,
            ],
            'genders' => $genderCollection,
            'url' => [
                'update' => route('contact.update', [
                    'vault' => $vault->id,
                    'contact' => $contact->id,
                ]),
                'show' => route('contact.show', [
                    'vault' => $vault->id,
                    'contact' => $contact->id,
                ]),
            ],
        ];
    }
}

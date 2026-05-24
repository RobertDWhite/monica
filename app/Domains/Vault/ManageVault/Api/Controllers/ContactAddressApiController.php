<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageContactAddresses\Services\AssociateAddressToContact;
use App\Domains\Contact\ManageContactAddresses\Services\RemoveAddressFromContact;
use App\Domains\Vault\ManageAddresses\Services\CreateAddress;
use App\Domains\Vault\ManageAddresses\Services\UpdateAddress;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Addresses
 */
class ContactAddressApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        $address = (new CreateAddress)->execute([
            'account_id' => $request->user()->account_id,
            'author_id' => $request->user()->id,
            'vault_id' => $vaultId,
            'address_type_id' => $request->input('address_type_id'),
            'line_1' => $request->input('line_1'),
            'line_2' => $request->input('line_2'),
            'city' => $request->input('city'),
            'province' => $request->input('province'),
            'postal_code' => $request->input('postal_code'),
            'country' => $request->input('country'),
        ]);

        (new AssociateAddressToContact)->execute($this->baseData($request, $vaultId, $contactId) + [
            'address_id' => $address->id,
            'is_past_address' => $request->boolean('is_past_address'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $addressId)
    {
        (new UpdateAddress)->execute([
            'account_id' => $request->user()->account_id,
            'author_id' => $request->user()->id,
            'vault_id' => $vaultId,
            'address_id' => (int) $addressId,
            'address_type_id' => $request->input('address_type_id'),
            'line_1' => $request->input('line_1'),
            'line_2' => $request->input('line_2'),
            'city' => $request->input('city'),
            'province' => $request->input('province'),
            'postal_code' => $request->input('postal_code'),
            'country' => $request->input('country'),
        ]);

        $contact = $this->findContact($request, $vaultId, $contactId);
        $contact->addresses()->updateExistingPivot((int) $addressId, [
            'is_past_address' => $request->boolean('is_past_address'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $addressId)
    {
        (new RemoveAddressFromContact)->execute($this->baseData($request, $vaultId, $contactId) + [
            'address_id' => (int) $addressId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
